require "rails_helper"

RSpec.describe Ops::Roles::Settings::Update do
  subject(:result) do
    described_class.call(server_configuration: server, channel_id:, log_on_assign: false)
  end

  let(:server) { create(:server_configuration) }
  let!(:setting) { server.create_role_setting! }
  let(:channel_id) { 99 }

  it "sets the role settings" do
    expect(result.success?).to be(true)
    expect(setting.reload).to have_attributes(channel_id: 99, log_on_assign: false)
  end

  context "updating existing values" do
    before do
      setting.update!(channel_id: 1)
    end

    it "updates them in place" do
      result
      expect(setting.reload.channel_id).to eq(99)
    end
  end
end
