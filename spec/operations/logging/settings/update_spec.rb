# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Logging::Settings::Update do
  subject(:result) { described_class.call(server_configuration: server, channel_id:) }

  let(:server) { create(:server_configuration, discord_id: 1) }
  let!(:setting) { server.create_logging_setting! }
  let(:channel_id) { 555 }

  context "with a channel" do
    it "sets the channel" do
      expect(result.success?).to be(true)
      expect(setting.reload.channel_id).to eq(555)
    end
  end

  context "without a channel" do
    let(:channel_id) { nil }

    it "fails and leaves the channel unset" do
      expect(result.failure?).to be(true)
      expect(setting.reload.channel_id).to be_nil
    end
  end

  context "updating an already-set channel" do
    before do
      setting.update!(channel_id: 111)
    end

    let(:channel_id) { 222 }

    it "updates it" do
      result
      expect(setting.reload.channel_id).to eq(222)
    end
  end

  context "when the chosen channel is visible to @everyone" do
    before do
      create(:server_channel, server_configuration: server, discord_id: 555)
    end

    it "saves but returns a visibility warning" do
      expect(result.success?).to be(true)
      expect(result.warnings).to include(/@everyone/)
    end
  end

  context "when the chosen channel is hidden from @everyone" do
    let(:channel) { create(:server_channel, server_configuration: server, discord_id: 555) }

    before do
      create(:channel_overwrite, server_channel: channel, target_id: 1, deny: ServerChannel::VIEW_CHANNEL)
    end

    it "saves with no warning" do
      expect(result.warnings).to be_empty
    end
  end
end
