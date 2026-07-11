# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::ServerCleanup do
  subject(:handle) { described_class.new(event).handle }

  let(:event) { double("event", server: 1) }

  let(:op) { Ops::ServerConfiguration::Destroy }

  context "for a configured server" do
    let!(:config) { create(:server_configuration, discord_id: 1) }

    it "calls the destroy operation with the config" do
      expect(op).to receive(:call).with(server_configuration: config)
      handle
    end
  end

  context "for an unconfigured server" do
    it "does not call the destroy operation" do
      expect(op).not_to receive(:call)
      handle
    end
  end
end
