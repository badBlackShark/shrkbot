# frozen_string_literal: true

require "rails_helper"

RSpec.describe Roles::Pick do
  subject(:handle) { described_class.new(event).handle }

  let(:server_config) { create(:server_configuration) }
  let(:setting) { create(:role_setting, server_configuration: server_config) }
  let(:set) { create(:role_set, role_setting: setting, selection_mode: "single") }
  let!(:red) { create(:assignable_role, role_set: set, role_id: 100, position: 0) }
  let!(:blue) { create(:assignable_role, role_set: set, role_id: 200, position: 1) }

  before do
    create(:server_role, server_configuration: server_config, discord_id: 100, name: "Red")
    create(:server_role, server_configuration: server_config, discord_id: 200, name: "Blue")
  end

  let(:user) { double("user", id: 42) }
  let(:member) { double("member", roles: [], modify_roles: nil, mention: "<@42>") }
  let(:server) { double("server", member:) }
  let(:bot) { double("bot") }
  let(:event) do
    double("event", custom_id: Roles::CustomId.pick(set, blue), server:, user:, respond: nil, bot:)
  end

  before do
    allow(Bot::ActivityLog).to receive(:enabled?).and_return(true)
    allow(Bot::ActivityLog).to receive(:post)
  end

  it "adds the picked role and removes the other roles in the set" do
    expect(member).to receive(:modify_roles).with([200], [100])
    handle
  end

  it "logs the role the user gained" do
    expect(Bot::ActivityLog).to receive(:post).with(
      server_config,
      bot:,
      title: "Roles updated",
      body: "<@42> gained **Blue**.",
      meta: "Self-assigned via the \"#{set.name}\" role menu"
    )
    handle
  end

  it "confirms what changed ephemerally" do
    expect(event).to receive(:respond).with(content: "You now have **Blue**.", ephemeral: true)
    handle
  end

  context "when the pick replaces a role the member has" do
    let(:member) { double("member", roles: [double("role", id: 100)], modify_roles: nil, mention: "<@42>") }

    it "names the swapped-out role in the confirmation" do
      expect(event).to receive(:respond).with(content: "You now have **Blue** - swapped out **Red**.", ephemeral: true)
      handle
    end
  end

  context "when the member picks the role they already have" do
    let(:member) { double("member", roles: [double("role", id: 200)], modify_roles: nil, mention: "<@42>") }

    it "removes it without replacement (toggle off)" do
      expect(member).to receive(:modify_roles).with([], [200])
      handle
    end

    it "confirms the removal" do
      expect(event).to receive(:respond).with(content: "Removed **Blue**.", ephemeral: true)
      handle
    end

    it "logs the role the user lost" do
      expect(Bot::ActivityLog).to receive(:post).with(
        server_config,
        bot:,
        title: "Roles updated",
        body: "<@42> lost **Blue**.",
        meta: "Self-assigned via the \"#{set.name}\" role menu"
      )
      handle
    end
  end

  context "when the custom id references a role outside the set" do
    let(:event) do
      double("event", custom_id: "roles:pick:#{set.id}:999", server:, user:, respond: nil)
    end

    it "makes no change" do
      expect(member).not_to receive(:modify_roles)
      handle
    end
  end

  context "outside a server (no member to assign)" do
    let(:server) { nil }

    it "does nothing" do
      expect(event).not_to receive(:respond)
      handle
    end
  end

  it "never DMs the user" do
    expect(user).not_to receive(:pm)
    handle
  end
end
