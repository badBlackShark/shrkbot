# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Moderation::StaffRoleCard do
  include_context "component view context"

  subject(:html) do
    described_class.new(
      server_configuration: config,
      staff_role_id:,
      missing:,
      permission_warning:
    ).render_in(view_context)
  end

  let(:config) { create(:server_configuration, discord_id: 900_000_001) }
  let(:role) { create(:server_role, server_configuration: config, discord_id: 501, name: "Moderators", color: 0, permissions: 0) }
  let(:staff_role_id) { nil }
  let(:missing) { false }
  let(:permission_warning) { false }

  before { role }

  it "renders the staff role select with correct field name" do
    expect(html).to include('name="moderation[staff_role_id]"')
  end

  it "renders the role name as an option" do
    expect(html).to include("Moderators")
  end

  it "uses the default colour for a zero-colour role" do
    expect(html).to include("#99aab5")
  end

  context "when the role has a colour" do
    let(:role) { create(:server_role, server_configuration: config, discord_id: 501, name: "Moderators", color: 0xE67E22) }

    it "renders the role colour as a hex dot" do
      expect(html).to include("#e67e22")
    end
  end

  context "when the role is missing" do
    let(:staff_role_id) { 999 }
    let(:missing) { true }

    it "renders the missing warning" do
      expect(html).to include("Required. Every sub-plugin stays off")
    end

    it "does not render the normal help text" do
      expect(html).not_to include("Shared by every Moderation sub-plugin")
    end
  end

  context "when there is a permission warning" do
    let(:staff_role_id) { 501 }
    let(:permission_warning) { true }

    it "renders the permission warning bold text" do
      expect(html).to include("Staff pings will fail.")
    end

    it "renders the permission warning body" do
      expect(html).to include("Mention All Roles")
    end
  end

  describe "the staff permission warning" do
    let(:warning) { Nokogiri::HTML5.fragment(html).at_css("[data-controller=live-warning]") }

    before do
      create(:server_role, server_configuration: config, discord_id: 502, permissions: ServerRole::MANAGE_MESSAGES)
      create(:server_role, server_configuration: config, discord_id: 503, permissions: ServerRole::ADMINISTRATOR)
    end

    it "watches the staff role field for a role without Manage Messages" do
      expect(JSON.parse(warning["data-live-warning-fields-value"])).to eq(["moderation[staff_role_id]"])
      expect(warning["data-live-warning-rule-value"]).to eq("includes-any")
    end

    it "lists only the roles that cannot see staff commands" do
      expect(JSON.parse(warning["data-live-warning-list-value"])).to eq(["501"])
    end

    it "is hidden while no role is saved" do
      expect(warning.key?("hidden")).to be(true)
    end

    context "when the saved role lacks Manage Messages" do
      let(:staff_role_id) { 501 }

      it "shows the warning text" do
        expect(warning.key?("hidden")).to be(false)
        expect(warning.text).to include("This role can't see staff commands.")
      end
    end

    context "when the saved role has Manage Messages" do
      let(:staff_role_id) { 502 }

      it "is hidden" do
        expect(warning.key?("hidden")).to be(true)
      end
    end

    context "when the saved role is gone" do
      let(:staff_role_id) { 999 }

      it "is hidden" do
        expect(warning.key?("hidden")).to be(true)
      end
    end
  end
end
