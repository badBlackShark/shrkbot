# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Moderation::StaffRoleCard do
  include_context "component view context"

  subject(:html) do
    described_class.new(
      server_configuration: config,
      staff_role_id:
    ).render_in(view_context)
  end

  let(:config) { create(:server_configuration, discord_id: 900_000_001) }
  let(:role) { create(:server_role, server_configuration: config, discord_id: 501, name: "Moderators", color: 0, permissions: 0) }
  let(:staff_role_id) { nil }

  before { role }

  it "renders the staff role select with correct field name" do
    expect(html).to include('name="moderation[staff_role_id]"')
  end

  it "explains the staff role under the picker" do
    expect(html).to include("Exempt from all checks and optionally pinged for alerts.")
  end

  it "exposes the requirement on the select" do
    expect(Nokogiri::HTML5.fragment(html).at_css("select")["aria-required"]).to eq("true")
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

  describe "the staff permission warning" do
    let(:warning) { Nokogiri::HTML5.fragment(html).at_css("[data-controller=live-warning]") }
    let(:callout) { warning.at_css("[data-live-warning-target=callout]") }

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
      expect(callout.key?("hidden")).to be(true)
    end

    context "when the saved role lacks Manage Messages" do
      let(:staff_role_id) { 501 }

      it "shows the warning text" do
        expect(callout.key?("hidden")).to be(false)
        expect(warning.text).to include(%(This role can't use "Report as scam".))
      end
    end

    context "when the saved role has Manage Messages" do
      let(:staff_role_id) { 502 }

      it "is hidden" do
        expect(callout.key?("hidden")).to be(true)
      end
    end

    context "when the saved role is gone" do
      let(:staff_role_id) { 999 }

      it "is hidden" do
        expect(callout.key?("hidden")).to be(true)
      end
    end
  end
end
