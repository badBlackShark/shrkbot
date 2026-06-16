require "rails_helper"

RSpec.describe Ops::SetLoggingChannel do
  let(:server) { create(:server_configuration, discord_id: 1) }

  it "fails without a channel" do
    result = described_class.call(server_configuration: server, channel_id: nil)
    expect(result.failure?).to be(true)
    expect(server.reload.logging_setting).to be_nil
  end

  it "creates the logging setting with the channel" do
    result = described_class.call(server_configuration: server, channel_id: 555)

    expect(result.success?).to be(true)
    expect(server.reload.logging_setting.channel_id).to eq(555)
  end

  it "updates an existing logging setting" do
    server.create_logging_setting!(channel_id: 111)

    described_class.call(server_configuration: server, channel_id: 222)

    expect(server.reload.logging_setting.channel_id).to eq(222)
  end
end
