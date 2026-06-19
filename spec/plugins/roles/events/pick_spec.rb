require "rails_helper"

RSpec.describe Roles::Pick do
  subject(:handle) { described_class.new(event).handle }

  let(:setting) { create(:role_setting, notify_on_assign: false) }
  let(:set) { create(:role_set, role_setting: setting, selection_mode: "single") }
  let!(:red) { create(:assignable_role, role_set: set, role_id: 100, label: "Red", position: 0) }
  let!(:blue) { create(:assignable_role, role_set: set, role_id: 200, label: "Blue", position: 1) }

  let(:user) { double("user", id: 42) }
  let(:member) { double("member", roles: [], modify_roles: nil) }
  let(:server) { double("server") }
  let(:event) do
    double("event", custom_id: Roles::CustomId.pick(set, blue), server:, user:, update_message: nil)
  end

  before do
    allow(server).to receive(:member).with(42).and_return(member)
  end

  it "adds the picked role and removes the other roles in the set" do
    expect(member).to receive(:modify_roles).with([200], [100])
    handle
  end

  it "re-renders the picker via update_message" do
    expect(event).to receive(:update_message)
    handle
  end

  context "when the custom id references a role outside the set" do
    let(:event) do
      double("event", custom_id: "roles:pick:#{set.id}:999", server:, user:, update_message: nil)
    end

    it "makes no change" do
      expect(member).not_to receive(:modify_roles)
      handle
    end
  end

  context "when notify_on_assign is on" do
    let(:setting) { create(:role_setting, notify_on_assign: true) }

    it "DMs the user their selection" do
      expect(user).to receive(:pm).with("**#{set.name}**: Blue")
      handle
    end
  end

  context "when notify_on_assign is off" do
    it "does not DM the user" do
      expect(user).not_to receive(:pm)
      handle
    end
  end
end
