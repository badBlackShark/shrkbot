# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Moderation::StaffRoleCard do
  include_context "component view context"

  let(:config) { create(:server_configuration, discord_id: 900_000_001) }
  let(:role) { create(:server_role, server_configuration: config, discord_id: 501, name: "Moderators", color: 0) }

  before { role }

  subject(:html) do
    described_class.new(
      server_configuration: config,
      staff_role_id: nil,
      permission_warning: false,
      staff_permission_warning: false
    ).render_in(view_context)
  end

  it "renders the staff role select with correct field name" do
    expect(html).to include('name="moderation[staff_role_id]"')
  end

  it "explains the staff role under the picker" do
    expect(html).to include("Exempt from all checks and optionally pinged for alerts.")
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

  context "when there is a permission warning" do
    subject(:html) do
      described_class.new(
        server_configuration: config,
        staff_role_id: 501,
        permission_warning: true,
        staff_permission_warning: false
      ).render_in(view_context)
    end

    it "renders the permission warning bold text" do
      expect(html).to include("Staff pings will fail.")
    end

    it "renders the permission warning body" do
      expect(html).to include("Mention All Roles")
    end
  end

  context "when there is a staff permission warning" do
    subject(:html) do
      described_class.new(
        server_configuration: config,
        staff_role_id: 501,
        permission_warning: false,
        staff_permission_warning: true
      ).render_in(view_context)
    end

    it "renders the staff permission warning bold text" do
      expect(html).to include(CGI.escapeHTML(%(This role can't use "Report as scam".)))
    end

    it "renders the staff permission warning body" do
      expect(html).to include("Manage Messages")
    end
  end
end
