# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::ChannelUpsert do
  subject(:handle) { described_class.new(event).handle }

  let(:server) { double("server", id: 1) }
  let(:channel) { double("channel") }
  let(:event) { double("event", server:, channel:) }
  let(:op) { Ops::ServerConfiguration::ServerChannel::Upsert }

  context "for a configured server" do
    let!(:config) { create(:server_configuration, discord_id: 1) }

    before do
      allow(Bot::GuildMetadata).to receive(:channel_data).with(channel).and_return(:channel_data)
      allow(op).to receive(:call)
    end

    it "upserts just the one channel from the event" do
      expect(op).to receive(:call).with(server_configuration: config, channel: :channel_data)
      handle
    end

    it "writes only the channel the event names, never the whole guild" do
      expect(Ops::ServerConfiguration::ServerChannel::Sync).not_to receive(:call)
      handle
    end

    context "when event.channel is nil" do
      let(:channel) { nil }

      it "does not upsert a channel" do
        expect(op).not_to receive(:call)
        handle
      end
    end
  end

  context "for a non-guild channel (no server)" do
    let(:server) { nil }

    it "does nothing" do
      expect(op).not_to receive(:call)
      handle
    end
  end

  context "for a server with no configuration" do
    it "does nothing" do
      expect(op).not_to receive(:call)
      handle
    end
  end
end
