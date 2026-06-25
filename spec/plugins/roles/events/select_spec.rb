# frozen_string_literal: true

require "rails_helper"

RSpec.describe Roles::Select do
  subject(:handle) { described_class.new(event).handle }

  let(:set) { create(:role_set, selection_mode: "multi") }
  let(:server_config) { set.role_setting.server_configuration }
  let!(:news) { create(:assignable_role, role_set: set, role_id: 100, position: 0) }
  let!(:events_role) { create(:assignable_role, role_set: set, role_id: 200, position: 1) }

  before do
    create(:server_role, server_configuration: server_config, discord_id: 100, name: "News")
    create(:server_role, server_configuration: server_config, discord_id: 200, name: "Events")
    allow(ActivityLog).to receive(:record)
  end

  let(:user) { double("user", id: 42) }
  let(:member) { double("member", roles: [], modify_roles: nil, mention: "<@42>") }
  let(:server) { double("server", member: member) }
  let(:bot) { double("bot") }
  let(:event) do
    double("event", custom_id: Roles::CustomId.select(set), server:, user:, values: ["100"], update_message: nil, bot:)
  end

  it "adds the selected set roles and removes the unselected ones" do
    expect(member).to receive(:modify_roles).with([100], [200])
    handle
  end

  it "logs the gained role" do
    expect(ActivityLog).to receive(:record).with(
      server_config, :roles, :role_gained, bot:, actor: "<@42>", roles: ["News"]
    )
    handle
  end

  context "when the user swaps one role for another" do
    let(:member) { double("member", roles: [double("role", id: 200)], modify_roles: nil, mention: "<@42>") }

    it "logs the gained and lost roles as separate lines" do
      expect(ActivityLog).to receive(:record).with(
        server_config, :roles, :role_gained, bot:, actor: "<@42>", roles: ["News"]
      )
      expect(ActivityLog).to receive(:record).with(
        server_config, :roles, :role_lost, bot:, actor: "<@42>", roles: ["Events"]
      )
      handle
    end
  end

  context "when the user clears their roles" do
    let(:member) do
      double("member", roles: [double("role", id: 100), double("role", id: 200)], modify_roles: nil, mention: "<@42>")
    end
    let(:event) do
      double("event", custom_id: Roles::CustomId.select(set), server:, user:, values: [], update_message: nil, bot:)
    end

    it "logs only the lost roles" do
      expect(ActivityLog).not_to receive(:record).with(server_config, :roles, :role_gained, any_args)
      expect(ActivityLog).to receive(:record).with(
        server_config, :roles, :role_lost, bot:, actor: "<@42>", roles: ["News", "Events"]
      )
      handle
    end
  end

  context "when the selection changes nothing" do
    let(:member) { double("member", roles: [double("role", id: 100)], modify_roles: nil, mention: "<@42>") }

    it "logs nothing" do
      expect(ActivityLog).not_to receive(:record)
      handle
    end
  end

  context "outside a server (no member to assign)" do
    let(:server) { nil }

    it "does nothing" do
      expect(event).not_to receive(:update_message)
      handle
    end
  end

  it "re-renders the picker via update_message" do
    expect(event).to receive(:update_message)
    handle
  end

  it "never DMs the user" do
    expect(user).not_to receive(:pm)
    handle
  end
end
