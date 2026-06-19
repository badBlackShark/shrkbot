require "rails_helper"

RSpec.describe Roles::Message do
  describe ".public_message" do
    context "for a multi-selection set" do
      subject(:message) { described_class.public_message(set) }

      let(:set) { create(:role_set, name: "Game Roles", selection_mode: "multi") }

      before do
        create(:assignable_role, role_set: set, label: "Gamer", emoji: "🎮", position: 0)
        create(:assignable_role, role_set: set, label: "Artist", emoji: nil, position: 1)
      end

      it "lists the set name and its roles in order" do
        expect(message[:content]).to eq("**Game Roles**\n🎮 Gamer\nArtist")
      end

      it "includes a manage button carrying the set's custom id" do
        button = message[:components].first[:components].first
        expect(button).to include(label: "Manage Roles", custom_id: Roles::CustomId.manage(set))
      end
    end

    context "for a single-selection set" do
      subject(:message) { described_class.public_message(set) }

      let(:set) { create(:role_set, name: "Color", selection_mode: "single") }
      let!(:red) { create(:assignable_role, role_set: set, role_id: 100, label: "Red", position: 0) }
      let!(:blue) { create(:assignable_role, role_set: set, role_id: 200, label: "Blue", position: 1) }

      it "renders the role buttons directly, no manage step" do
        buttons = message[:components].flat_map { |row| row[:components] }
        expect(buttons.map { |button| button[:custom_id] }).to eq([
          Roles::CustomId.pick(set, red),
          Roles::CustomId.pick(set, blue)
        ])
      end

      it "warns that picking replaces the current role" do
        expect(message[:content]).to include("replaces your current one")
      end

      it "chunks the buttons into rows of five" do
        6.times { |n| create(:assignable_role, role_set: set, role_id: 300 + n, position: 10 + n) }
        expect(message[:components].size).to eq(2)
      end
    end
  end

  describe ".multi_picker" do
    subject(:picker) { described_class.multi_picker(set, [200]) }

    let(:set) { create(:role_set, name: "Pings", selection_mode: "multi") }
    let!(:news) { create(:assignable_role, role_set: set, role_id: 100, label: "News", description: "Announcements", position: 0) }
    let!(:events) { create(:assignable_role, role_set: set, role_id: 200, label: "Events", description: nil, position: 1) }

    let(:select) { picker[:components].first[:components].first }

    it "is a string select carrying the set's custom id" do
      expect(select).to include(type: described_class::STRING_SELECT, custom_id: Roles::CustomId.select(set))
    end

    it "lets the user pick any number of roles in the set" do
      expect(select).to include(min_values: 0, max_values: 2)
    end

    it "pre-checks the roles the user already has" do
      defaults = select[:options].select { |option| option[:default] }
      expect(defaults.map { |option| option[:value] }).to eq(["200"])
    end

    it "carries a description only when the role has one" do
      news_option = select[:options].find { |option| option[:value] == "100" }
      expect(news_option).to include(description: "Announcements")
      expect(select[:options].find { |option| option[:value] == "200" }).not_to have_key(:description)
    end
  end

  describe ".selection_summary" do
    subject(:summary) { described_class.selection_summary(set, active) }

    let(:set) { create(:role_set, name: "Color") }

    before do
      create(:assignable_role, role_set: set, role_id: 100, label: "Red", position: 0)
      create(:assignable_role, role_set: set, role_id: 200, label: "Blue", position: 1)
    end

    context "with roles selected" do
      let(:active) { [200] }

      it "lists the chosen role labels" do
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
