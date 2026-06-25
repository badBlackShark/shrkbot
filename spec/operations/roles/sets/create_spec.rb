# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Roles::Sets::Create do
  subject(:result) { described_class.call(server_configuration: server, name: "Games", selection_mode: "multi") }

  let(:server) { create(:server_configuration) }
  let!(:setting) { server.create_role_setting! }

  it "creates a set under the role settings" do
    expect(result.success?).to be(true)
    expect(result.value).to have_attributes(name: "Games", selection_mode: "multi", position: 0)
    expect(setting.reload.role_sets.count).to eq(1)
  end

  context "when a set already exists" do
    before do
      create(:role_set, role_setting: setting, position: 0)
    end

    it "appends after the last position" do
      expect(result.value.position).to eq(1)
    end
  end
end
