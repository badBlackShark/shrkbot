require "rails_helper"

RSpec.describe Roles::Pick do
  subject(:handle) { described_class.new(event).handle }

  let(:set) { create(:role_set, selection_mode: "single") }
  let!(:red) { create(:assignable_role, role_set: set, role_id: 100, label: "Red", position: 0) }
  let!(:blue) { create(:assignable_role, role_set: set, role_id: 200, label: "Blue", position: 1) }

  let(:user) { double("user", id: 42) }
  let(:member) { double("member", roles: [], modify_roles: nil) }
  let(:server) { double("server", member: member) }
  let(:event) do
    double("event", custom_id: Roles::CustomId.pick(set, blue), server:, user:, respond: nil)
  end

  it "adds the picked role and removes the other roles in the set" do
    expect(member).to receive(:modify_roles).with([200], [100])
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
