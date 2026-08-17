# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::RoleUpsert do
  subject(:handle) { described_class.new(event).handle }

  let(:server) { double("server", id: 1) }
  let(:bot) { double("bot") }
  let(:role) { double("role") }
  let(:event) { double("event", server:, bot:, role:) }
  let(:op) { Ops::ServerConfiguration::ServerRole::Upsert }

  before do
    allow(Bot::GuildMetadata).to receive(:bot_role_position).with(server, bot).and_return(6)
  end

  context "for a configured server" do
    let!(:config) { create(:server_configuration, discord_id: 1) }

    before do
      allow(Bot::GuildMetadata).to receive(:role_data).with(role).and_return(:role_data)
      allow(op).to receive(:call)
    end

    it "upserts the role from the event" do
      expect(op).to receive(:call).with(server_configuration: config, role: :role_data)
      handle
    end

    it "writes only the role the event names, never the whole guild" do
      expect(Ops::ServerConfiguration::ServerRole::Sync).not_to receive(:call)
      handle
    end

    context "when event.role is nil" do
      let(:role) { nil }

      it "does not upsert a role" do
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
