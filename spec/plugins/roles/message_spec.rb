require "rails_helper"

RSpec.describe Roles::Message do
  let(:server_config) { create(:server_configuration) }
  let(:setting) { create(:role_setting, server_configuration: server_config) }

  def sync_role(discord_id, name)
    create(:server_role, server_configuration: server_config, discord_id: discord_id, name: name)
  end

  def container_blocks(rendered)
    rendered[:components].first[:components]
  end

  def text_block(rendered)
    container_blocks(rendered).find { |block| block[:type] == described_class::TEXT_DISPLAY }
  end

  def row_components(rendered)
    container_blocks(rendered)
      .select { |block| block[:type] == described_class::ACTION_ROW }
      .flat_map { |row| row[:components] }
  end

  describe ".public_message" do
    it "wraps the message in a container and sets the components-v2 flag" do
      set = create(:role_set, role_setting: setting, selection_mode: "multi")
      rendered = described_class.public_message(set)
      expect(rendered[:flags]).to eq(described_class::COMPONENTS_V2)
      expect(rendered[:components].first[:type]).to eq(described_class::CONTAINER)
    end

    context "for a multi-selection set" do
      subject(:rendered) { described_class.public_message(set) }

      let(:set) { create(:role_set, role_setting: setting, name: "Game Roles", selection_mode: "multi") }

      before do
        create(:assignable_role, role_set: set, role_id: 100, emoji: "🎮", position: 0)
        create(:assignable_role, role_set: set, role_id: 200, emoji: nil, position: 1)
        sync_role(100, "Gamer")
        sync_role(200, "Artist")
      end

      it "lists the set name and synced role names in order" do
        expect(text_block(rendered)[:content]).to eq("**Game Roles**\n🎮 Gamer\nArtist")
      end

      it "offers a single manage button" do
        expect(row_components(rendered)).to contain_exactly(
          hash_including(label: "Manage Roles", custom_id: Roles::CustomId.manage(set))
        )
      end
    end

    context "for a single-selection set" do
      subject(:rendered) { described_class.public_message(set) }

      let(:set) { create(:role_set, role_setting: setting, name: "Color", selection_mode: "single") }
      let!(:red) { create(:assignable_role, role_set: set, role_id: 100, position: 0) }
      let!(:blue) { create(:assignable_role, role_set: set, role_id: 200, position: 1) }

      before do
        sync_role(100, "Red")
        sync_role(200, "Blue")
      end

      it "renders a button per role, labelled with the synced role name" do
        buttons = row_components(rendered)
        expect(buttons.map { |button| button[:label] }).to eq(["Red", "Blue"])
        expect(buttons.map { |button| button[:custom_id] }).to eq([
          Roles::CustomId.pick(set, red),
          Roles::CustomId.pick(set, blue)
        ])
      end

      it "warns that picking replaces the current role" do
        expect(text_block(rendered)[:content]).to include("replaces your current one")
      end

      it "chunks the buttons into rows of five" do
        6.times do |n|
          create(:assignable_role, role_set: set, role_id: 300 + n, position: 10 + n)
          sync_role(300 + n, "extra-#{n}")
        end
        rows = container_blocks(rendered).select { |block| block[:type] == described_class::ACTION_ROW }
        expect(rows.size).to eq(2)
      end
    end

    context "with a role that has not been synced" do
      subject(:rendered) { described_class.public_message(set) }

      let(:set) { create(:role_set, role_setting: setting, selection_mode: "single") }

      before do
        create(:assignable_role, role_set: set, role_id: 999, position: 0)
      end

      it "falls back to a placeholder so the button is never empty" do
        expect(row_components(rendered).first[:label]).to eq(described_class::UNKNOWN_ROLE)
      end
    end
  end

  describe ".multi_picker" do
    subject(:select) do
      row_components(described_class.multi_picker(set, [200])).first
    end

    let(:set) { create(:role_set, role_setting: setting, name: "Pings", selection_mode: "multi") }

    before do
      create(:assignable_role, role_set: set, role_id: 100, description: "Announcements", position: 0)
      create(:assignable_role, role_set: set, role_id: 200, description: nil, position: 1)
      sync_role(100, "News")
      sync_role(200, "Events")
    end

    it "sets the components-v2 flag" do
      expect(described_class.multi_picker(set, [])[:flags]).to eq(described_class::COMPONENTS_V2)
    end

    it "is a string select carrying the set's custom id" do
      expect(select).to include(type: described_class::STRING_SELECT, custom_id: Roles::CustomId.select(set))
    end

    it "lets the user pick any number of roles in the set" do
      expect(select).to include(min_values: 0, max_values: 2)
    end

    it "labels options with the synced role names" do
      expect(select[:options].map { |option| option[:label] }).to contain_exactly("News", "Events")
    end

    it "pre-checks the roles the user already has" do
      defaults = select[:options].select { |option| option[:default] }
      expect(defaults.map { |option| option[:value] }).to eq(["200"])
    end

    it "carries a description only when the role has one" do
      news = select[:options].find { |option| option[:value] == "100" }
      events = select[:options].find { |option| option[:value] == "200" }
      expect(news).to include(description: "Announcements")
      expect(events).not_to have_key(:description)
    end
  end

  describe ".selection_summary" do
    subject(:summary) { described_class.selection_summary(set, active) }

    let(:set) { create(:role_set, role_setting: setting, name: "Color") }

    before do
      create(:assignable_role, role_set: set, role_id: 100, position: 0)
      create(:assignable_role, role_set: set, role_id: 200, position: 1)
      sync_role(100, "Red")
      sync_role(200, "Blue")
    end

    context "with roles selected" do
      let(:active) { [200] }

      it "lists the chosen synced role names" do
        expect(summary).to eq("**Color**: Blue")
      end
    end

    context "with nothing selected" do
      let(:active) { [] }

      it "says none" do
        expect(summary).to eq("**Color**: none")
      end
    end
  end
end
