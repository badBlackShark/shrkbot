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
  let(:server) { double("server", member: member) }
  let(:bot) { double("bot") }
  let(:event) do
    double("event", custom_id: Roles::CustomId.pick(set, blue), server:, user:, respond: nil, bot:)
  end

  before do
    allow(ActivityLog).to receive(:record)
  end

  it "adds the picked role and removes the other roles in the set" do
    expect(member).to receive(:modify_roles).with([200], [100])
    handle
  end

  it "logs the role the user gained" do
    expect(ActivityLog).to receive(:record).with(
      server_config, :roles, :role_gained, bot:, actor: "<@42>", roles: ["Blue"]
    )
    handle
  end

  it "confirms the new selection ephemerally" do
    expect(event).to receive(:respond).with(content: "**#{set.name}**: Blue", ephemeral: true)
    handle
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
