# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::RoleRemoval do
  subject(:handle) { described_class.new(event).handle }

  let(:server) { double("server", id: 1) }
  let(:bot) { double("bot") }
  let(:event) { double("event", server:, bot:, id: 111) }
  let(:op) { Ops::ServerConfiguration::ServerRole::Destroy }

  before do
    allow(Bot::GuildMetadata).to receive(:bot_role_position).with(server, bot).and_return(6)
  end

  context "for a configured server" do
    let!(:config) { create(:server_configuration, discord_id: 1) }

    context "with a matching local row" do
      let!(:role) { create(:server_role, server_configuration: config, discord_id: 111) }

      it "destroys just the matching row" do
        expect(op).to receive(:call).with(server_role: role)
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
