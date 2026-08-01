# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::ChannelRemoval do
  subject(:handle) { described_class.new(event).handle }

  let(:server) { double("server", id: 1) }
  let(:event) { double("event", server:, id: 111) }
  let(:op) { Ops::ServerConfiguration::ServerChannels::Destroy }

  context "for a configured server" do
    let!(:config) { create(:server_configuration, discord_id: 1) }

    context "with a matching local row" do
      let!(:channel) { create(:server_channel, server_configuration: config, discord_id: 111) }

      it "destroys just the matching row" do
        expect(op).to receive(:call).with(server_channel: channel)
        handle
      end
    end

    context "with no matching local row" do
      it "does nothing" do
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
