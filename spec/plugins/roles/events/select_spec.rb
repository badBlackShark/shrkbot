require "rails_helper"

RSpec.describe Roles::Select do
  subject(:handle) { described_class.new(event).handle }

  let(:setting) { create(:role_setting, notify_on_assign: false) }
  let(:set) { create(:role_set, role_setting: setting, selection_mode: "multi") }
  let!(:news) { create(:assignable_role, role_set: set, role_id: 100, label: "News", position: 0) }
  let!(:events_role) { create(:assignable_role, role_set: set, role_id: 200, label: "Events", position: 1) }

  let(:user) { double("user", id: 42) }
  let(:member) { double("member", modify_roles: nil) }
  let(:server) { double("server", member: member) }
  let(:event) do
    double("event", custom_id: Roles::CustomId.select(set), server:, user:, values: ["100"], update_message: nil)
  end

  it "adds the selected set roles and removes the unselected ones" do
    expect(member).to receive(:modify_roles).with([100], [200])
    handle
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

  context "when notify_on_assign is on" do
    let(:setting) { create(:role_setting, notify_on_assign: true) }

    it "DMs the user their resulting selection" do
      expect(user).to receive(:pm).with("**#{set.name}**: News")
      handle
    end
  end
end
