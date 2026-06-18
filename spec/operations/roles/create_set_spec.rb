require "rails_helper"

RSpec.describe Ops::Roles::CreateSet do
  subject(:result) { described_class.call(server_configuration: server, name: "Games", selection_mode: "multi") }

  let(:server) { create(:server_configuration) }

  it "creates a set, auto-creating the role settings if absent" do
    expect(result.success?).to be(true)
    expect(result.value).to have_attributes(name: "Games", selection_mode: "multi", position: 0)
    expect(server.reload.role_setting.role_sets.count).to eq(1)
  end

  context "when a set already exists" do
    let(:setting) { create(:role_setting, server_configuration: server) }

    before { create(:role_set, role_setting: setting, position: 0) }

    it "appends after the last position" do
      expect(result.value.position).to eq(1)
    end
  end
end
