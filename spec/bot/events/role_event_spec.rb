# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::RoleEvent do
  subject(:handle) { klass.new(event).handle }

  let(:server) { double("server", id: 1) }
  let(:bot) { double("bot") }
  let(:event) { double("event", server:, bot:) }
  let(:klass) { Class.new(described_class) { define_method(:apply) { |_config| } } }
  let(:position_sync) { Ops::ServerConfiguration::BotRolePosition::Sync }

  before do
    allow(Bot::GuildMetadata).to receive(:bot_role_position).with(server, bot).and_return(6)
  end

  context "for a configured server" do
    let!(:config) { create(:server_configuration, discord_id: 1) }

    it "syncs the bot's role position after applying" do
      expect(position_sync).to receive(:call).with(server_configuration: config, position: 6)
      handle
    end

    context "without an #apply implementation" do
      let(:klass) { Class.new(described_class) }

      it "is abstract" do
        expect { handle }.to raise_error(AbstractMethodError)
      end
    end
  end

  context "for an uncached server (no server)" do
    let(:server) { nil }

    it "does nothing" do
      expect(position_sync).not_to receive(:call)
      handle
    end
  end

  context "for a server with no configuration" do
    it "does nothing" do
      expect(position_sync).not_to receive(:call)
      handle
    end
  end
end
