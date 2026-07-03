# frozen_string_literal: true

require "rails_helper"

RSpec.describe GuildMetadata do
  describe ".channels" do
    subject(:channels) { described_class.channels(server) }

    let(:overwrite) do
      double("overwrite", id: 555, type: :role, allow: double(bits: 1024), deny: double(bits: 2048))
    end
    let(:channel) do
      double("channel", id: 111, name: "general", type: 0, position: 3, parent_id: 999,
        permission_overwrites: {555 => overwrite})
    end
    let(:server) { double("server", channels: [channel]) }

    it "maps each channel to a plain hash with its position and category" do
      expect(channels).to eq([
        {discord_id: 111, name: "general", channel_type: 0, position: 3, parent_id: 999, overwrites: [
          {target_id: 555, target_type: "role", allow: 1024, deny: 2048}
        ]}
      ])
    end
  end

  describe ".roles" do
    subject(:roles) { described_class.roles(server) }

    let(:server) { double("server", roles: [double("role", id: 222, name: "Admin", position: 3, managed?: false, color: double(combined: 0x37a79e))]) }

    it "maps each role to a plain hash with its position, managed flag, and colour" do
      expect(roles).to eq([{discord_id: 222, name: "Admin", position: 3, managed: false, color: 0x37a79e}])
    end
  end

  describe ".bot_role_position" do
    subject(:position) { described_class.bot_role_position(server, bot) }

    let(:bot) { double("bot", profile: double("profile", id: 99)) }
    let(:server) { double("server") }

    before { allow(server).to receive(:member).with(99).and_return(member) }

    context "when the bot has roles above @everyone" do
      let(:member) { double("member", roles: [double("role", position: 2), double("role", position: 5)]) }

      it "is the bot's highest role position" do
        expect(position).to eq(5)
      end
    end

    context "when the bot has only @everyone" do
      let(:member) { double("member", roles: []) }

      it "is 0" do
        expect(position).to eq(0)
      end
    end
  end

  describe ".sync" do
    subject(:sync) { described_class.sync(server, bot) }

    let(:server) { double("server", id: 77, channels: [], roles: []) }
    let(:bot) { double("bot") }
    let(:config) { instance_double(ServerConfiguration) }

    before do
      allow(Ops::ServerConfiguration::Ensure).to receive(:call)
        .with(discord_id: 77).and_return(double(value: config))
      allow(described_class).to receive(:bot_role_position).with(server, bot).and_return(7)
      allow(ServerOnboarder).to receive(:notify)
    end

    it "ensures the config, then syncs channels and roles, then reconciles deletions" do
      expect(Ops::ServerConfiguration::ServerChannels::Sync).to receive(:call).with(server_configuration: config, channels: [])
      expect(Ops::ServerConfiguration::ServerRoles::Sync).to receive(:call).with(server_configuration: config, roles: [], bot_role_position: 7)
      expect(Ops::ServerConfiguration::Channels::Reconcile).to receive(:call).with(server_configuration: config, bot:)
      sync
    end

    it "onboards the server" do
      allow(Ops::ServerConfiguration::ServerChannels::Sync).to receive(:call)
      allow(Ops::ServerConfiguration::ServerRoles::Sync).to receive(:call)
      allow(Ops::ServerConfiguration::Channels::Reconcile).to receive(:call)
      expect(ServerOnboarder).to receive(:notify).with(bot, server, config)
      sync
    end

    it "returns the config" do
      allow(Ops::ServerConfiguration::ServerChannels::Sync).to receive(:call)
      allow(Ops::ServerConfiguration::ServerRoles::Sync).to receive(:call)
      allow(Ops::ServerConfiguration::Channels::Reconcile).to receive(:call)
      expect(sync).to eq(config)
    end
  end
end
