require "rails_helper"

RSpec.describe ChannelCleanup do
  subject(:handle) { described_class.new(event).handle }

  let(:bot) { double("bot") }
  let(:server) { double("server", id: 1) }
  let(:event) { double("event", server:, id: 555, bot:) }

  let(:op) { Ops::ServerConfiguration::Channels::DisablePlugins }

  context "for a guild channel of a configured server" do
    let!(:config) { create(:server_configuration, discord_id: 1) }

    it "hands the deleted channel to the disable operation" do
      expect(op).to receive(:call).with(server_configuration: config, channel_id: 555, bot:)
      handle
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
