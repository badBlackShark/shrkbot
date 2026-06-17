require "rails_helper"

RSpec.describe Ops::Roles::SetSettings do
  subject(:result) do
    described_class.call(server_configuration: server, channel_id:, notify_on_assign: true, log_on_assign: false)
  end

  let(:server) { create(:server_configuration) }
  let(:channel_id) { 99 }

  it "creates the role settings" do
    expect(result.success?).to be(true)
    expect(server.reload.role_setting).to have_attributes(channel_id: 99, notify_on_assign: true, log_on_assign: false)
  end

  context "with existing settings" do
    before { server.create_role_setting!(channel_id: 1, notify_on_assign: false) }

    it "updates them in place" do
      result
      expect(server.reload.role_setting.channel_id).to eq(99)
    end
  end
end
