require "rails_helper"

RSpec.describe Ops::ServerConfiguration::SetLoggingChannel do
  subject(:result) { described_class.call(server_configuration: server, channel_id:) }

  let(:server) { create(:server_configuration, discord_id: 1) }
  let(:channel_id) { 555 }

  context "without a channel" do
    let(:channel_id) { nil }

    it "fails and creates no setting" do
      expect(result.failure?).to be(true)
      expect(server.reload.logging_setting).to be_nil
    end
  end

  context "with a channel" do
    it "creates the logging setting" do
      expect(result.success?).to be(true)
      expect(server.reload.logging_setting.channel_id).to eq(555)
    end
  end

  context "with an existing setting" do
    before { server.create_logging_setting!(channel_id: 111) }

    let(:channel_id) { 222 }

    it "updates it" do
      result
      expect(server.reload.logging_setting.channel_id).to eq(222)
    end
  end
end
