require "rails_helper"

RSpec.describe GuildMetadata do
  describe ".channels" do
    subject(:channels) { described_class.channels(server) }

    let(:overwrite) do
      double("overwrite", id: 555, type: :role, allow: double(bits: 1024), deny: double(bits: 2048))
    end
    let(:channel) do
      double("channel", id: 111, name: "general", type: 0,
        permission_overwrites: {555 => overwrite})
    end
    let(:server) { double("server", channels: [channel]) }

    it "maps each channel to a plain hash" do
      expect(channels).to eq([
        {discord_id: 111, name: "general", channel_type: 0, overwrites: [
          {target_id: 555, target_type: "role", allow: 1024, deny: 2048}
        ]}
      ])
    end
  end

  describe ".roles" do
    subject(:roles) { described_class.roles(server) }

    let(:server) { double("server", roles: [double("role", id: 222, name: "Admin")]) }

    it "maps each role to a plain hash" do
      expect(roles).to eq([{discord_id: 222, name: "Admin"}])
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
    end

    it "ensures the config, then syncs channels and roles, then reconciles deletions" do
      expect(Ops::ServerConfiguration::SyncChannels).to receive(:call).with(server_configuration: config, channels: [])
      expect(Ops::ServerConfiguration::SyncRoles).to receive(:call).with(server_configuration: config, roles: [])
      expect(Ops::ServerConfiguration::ReconcileDeletedChannels).to receive(:call).with(server_configuration: config, bot:)
      sync
    end

    it "returns the config" do
      allow(Ops::ServerConfiguration::SyncChannels).to receive(:call)
      allow(Ops::ServerConfiguration::SyncRoles).to receive(:call)
      allow(Ops::ServerConfiguration::ReconcileDeletedChannels).to receive(:call)
      expect(sync).to eq(config)
    end
  end
end
