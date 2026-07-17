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
    allow(Bot::ActivityLog).to receive(:enabled?).and_return(true)
    allow(Bot::ActivityLog).to receive(:post)
  end

  let(:user) { double("user", id: 42) }
  let(:member) { double("member", roles: [], modify_roles: nil, mention: "<@42>") }
  let(:server) { double("server", id: server_config.discord_id, member:) }
  let(:bot) { double("bot") }
  let(:event) do
    double("event", custom_id: Roles::CustomId.select(set), server:, user:, values: ["100"], update_message: nil, bot:)
  end

  it "adds the selected set roles and removes the unselected ones" do
    expect(member).to receive(:modify_roles).with([100], [200])
    handle
  end

  context "when the interaction comes from a different server than the set" do
    let(:server) { double("server", id: foreign_config.discord_id, member:) }
    let!(:foreign_config) do
      create(:server_configuration, discord_id: server_config.discord_id + 1).tap do |config|
        create(:role_setting, server_configuration: config)
      end
    end

    it "ignores it and changes no roles" do
      expect(member).not_to receive(:modify_roles)
      handle
    end
  end

  it "logs the gained role" do
    expect(Bot::ActivityLog).to receive(:post).with(
      server_config,
      bot:,
      title: "Roles updated",
      body: "<@42> gained **News**.",
      meta: "Self-assigned via the \"#{set.name}\" role menu"
    )
    handle
  end

  context "when the user swaps one role for another" do
    let(:member) { double("member", roles: [double("role", id: 200)], modify_roles: nil, mention: "<@42>") }

    it "logs one combined entry for the gained and lost roles" do
      expect(Bot::ActivityLog).to receive(:post).with(
        server_config,
        bot:,
        title: "Roles updated",
        body: "<@42> gained **News** and lost **Events**.",
        meta: "Self-assigned via the \"#{set.name}\" role menu"
      )
      handle
    end

    context "when only the gained toggle is enabled" do
      before do
        allow(Bot::ActivityLog).to receive(:enabled?).with(server_config, "roles.role_lost").and_return(false)
      end

      it "logs only the gained side" do
        expect(Bot::ActivityLog).to receive(:post).with(
          server_config,
          bot:,
          title: "Roles updated",
          body: "<@42> gained **News**.",
          meta: "Self-assigned via the \"#{set.name}\" role menu"
        )
        handle
      end
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
      expect(Bot::ActivityLog).to receive(:post).with(
        server_config,
        bot:,
        title: "Roles updated",
        body: "<@42> lost **News** and **Events**.",
        meta: "Self-assigned via the \"#{set.name}\" role menu"
      )
      handle
    end
  end

  context "when the selection changes nothing" do
    let(:member) { double("member", roles: [double("role", id: 100)], modify_roles: nil, mention: "<@42>") }

    it "logs nothing" do
      expect(Bot::ActivityLog).not_to receive(:post)
      handle
    end
  end

  context "when both log toggles are off" do
    let(:member) { double("member", roles: [double("role", id: 200)], modify_roles: nil, mention: "<@42>") }

    before do
      allow(Bot::ActivityLog).to receive(:enabled?).and_return(false)
    end

    it "logs nothing" do
      expect(Bot::ActivityLog).not_to receive(:post)
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
