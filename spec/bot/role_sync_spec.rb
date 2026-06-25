# frozen_string_literal: true

require "rails_helper"

RSpec.describe RoleSync do
  subject(:handle) { described_class.new(event).handle }

  let(:server) { double("server", id: 1) }
  let(:bot) { double("bot") }
  let(:event) { double("event", server:, bot:) }
  let(:op) { Ops::ServerConfiguration::ServerRoles::Sync }

  before do
    allow(GuildMetadata).to receive(:roles).with(server).and_return([:role_data])
    allow(GuildMetadata).to receive(:bot_role_position).with(server, bot).and_return(6)
  end

  context "for a configured server" do
    let!(:config) { create(:server_configuration, discord_id: 1) }

    it "re-syncs the server's roles and the bot's role position" do
      expect(op).to receive(:call).with(server_configuration: config, roles: [:role_data], bot_role_position: 6)
      handle
    end
  end

  context "for an uncached server (no server)" do
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
