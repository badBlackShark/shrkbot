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
      missing: false,
      permission_warning: false
    ).render_in(view_context)
  end

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
    subject(:html) do
      described_class.new(
        server_configuration: config,
        staff_role_id: 999,
        missing: true,
        permission_warning: false
      ).render_in(view_context)
    end

    it "renders the missing warning" do
      expect(html).to include("Required. Every sub-plugin stays off")
    end

    it "does not render the normal help text" do
      expect(html).not_to include("Shared by every Moderation sub-plugin")
    end
  end

  context "when there is a permission warning" do
    subject(:html) do
      described_class.new(
        server_configuration: config,
        staff_role_id: 501,
        missing: false,
        permission_warning: true
      ).render_in(view_context)
    end

    it "renders the permission warning bold text" do
      expect(html).to include("Staff pings will fail.")
    end

    it "renders the permission warning body" do
      expect(html).to include("Mention All Roles")
    end
  end
end
