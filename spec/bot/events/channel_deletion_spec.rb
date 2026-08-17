# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::ChannelDeletion do
  subject(:handle) { described_class.new(event).handle }

  let(:bot) { double("bot") }
  let(:server) { double("server", id: 1) }
  let(:event) { double("event", server:, id: 555, bot:) }

  let(:release) { Ops::ServerConfiguration::ServerChannel::ReleaseFromPlugins }
  let(:destroy) { Ops::ServerConfiguration::ServerChannel::Destroy }

  before do
    allow(release).to receive(:call)
    allow(destroy).to receive(:call)
  end

  context "for a guild channel of a configured server" do
    let!(:config) { create(:server_configuration, discord_id: 1) }

    it "releases the channel from every plugin that pointed at it" do
      expect(release).to receive(:call).with(server_configuration: config, channel_id: 555, bot:)
      handle
    end

    context "with a matching local row" do
      let!(:channel) { create(:server_channel, server_configuration: config, discord_id: 555) }

      it "destroys just the matching row" do
        expect(destroy).to receive(:call).with(server_channel: channel)
        handle
      end

      it "releases the channel before destroying the row its name is read from" do
        expect(release).to receive(:call).ordered
        expect(destroy).to receive(:call).ordered
        handle
      end
    end

    context "with no matching local row" do
      it "does not destroy anything" do
        expect(destroy).not_to receive(:call)
        handle
      end

      it "still releases the channel from the plugins" do
        expect(release).to receive(:call)
        handle
      end
    end
  end

  context "for a non-guild channel (no server)" do
    let(:server) { nil }

    it "does nothing" do
      expect(release).not_to receive(:call)
      expect(destroy).not_to receive(:call)
      handle
    end
  end

  context "for a server with no configuration" do
    it "does nothing" do
      expect(release).not_to receive(:call)
      expect(destroy).not_to receive(:call)
      handle
    end
  end
end
