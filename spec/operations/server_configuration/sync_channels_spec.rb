require "rails_helper"

RSpec.describe Ops::ServerConfiguration::SyncChannels do
  subject(:result) { described_class.call(server_configuration: server, channels:) }

  let(:server) { create(:server_configuration) }

  describe "upserting channels" do
    let(:channels) do
      [
        {discord_id: 111, name: "general", channel_type: 0, overwrites: []},
        {discord_id: 222, name: "Voice", channel_type: 2, overwrites: []}
      ]
    end

    it "creates a row per incoming channel" do
      expect { result }.to change { server.server_channels.count }.from(0).to(2)
    end

    context "when a channel was renamed since the last sync" do
      before { create(:server_channel, server_configuration: server, discord_id: 111, name: "old") }

      it "updates the existing row in place rather than duplicating" do
        result

        expect(server.server_channels.find_by(discord_id: 111).name).to eq("general")
        expect(server.server_channels.where(discord_id: 111).count).to eq(1)
      end
    end
  end

  describe "pruning" do
    let(:channels) { [{discord_id: 111, name: "general", channel_type: 0, overwrites: []}] }

    before { create(:server_channel, server_configuration: server, discord_id: 999, name: "gone") }

    it "removes channels no longer present" do
      result

      expect(server.server_channels.where(discord_id: 999)).to be_empty
    end

    it "leaves another server's channels untouched" do
      other = create(:server_channel, discord_id: 999)

      expect { result }.not_to change { ServerChannel.where(id: other.id).count }
    end
  end

  describe "overwrites" do
    let(:channels) do
      [{discord_id: 111, name: "general", channel_type: 0, overwrites: [
        {target_id: 555, target_type: "role", allow: 1024, deny: 2048}
      ]}]
    end

    it "syncs a channel's permission overwrites" do
      result

      overwrite = server.server_channels.find_by(discord_id: 111).channel_overwrites.sole
      expect(overwrite).to have_attributes(target_id: 555, target_type: "role", allow: 1024, deny: 2048)
    end

    context "when an overwrite was removed" do
      let(:channel) { create(:server_channel, server_configuration: server, discord_id: 111) }

      before { create(:channel_overwrite, server_channel: channel, target_id: 777) }

      it "prunes overwrites no longer present on the channel" do
        result

        expect(channel.channel_overwrites.where(target_id: 777)).to be_empty
      end
    end
  end
end
