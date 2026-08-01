# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::ServerConfiguration::ServerChannels::Upsert do
  subject(:result) { described_class.call(server_configuration: server, channel:) }

  let(:server) { create(:server_configuration) }
  let(:channel) do
    {discord_id: 111, name: "general", channel_type: 0, position: 2, parent_id: 999, overwrites: [
      {target_id: 555, target_type: "role", allow: 1024, deny: 2048}
    ]}
  end

  context "for an unseen discord_id" do
    it "creates a row" do
      expect { result }.to change { server.server_channels.count }.from(0).to(1)
    end

    it "stores the channel's attributes" do
      result

      expect(server.server_channels.find_by(discord_id: 111)).to have_attributes(
        name: "general", channel_type: 0, position: 2, parent_id: 999
      )
    end

    it "writes the channel's overwrites" do
      result

      overwrite = server.server_channels.find_by(discord_id: 111).channel_overwrites.sole
      expect(overwrite).to have_attributes(target_id: 555, target_type: "role", allow: 1024, deny: 2048)
    end
  end

  context "for a known discord_id" do
    let!(:existing) { create(:server_channel, server_configuration: server, discord_id: 111, name: "old", position: 9) }

    it "updates the existing row rather than creating a second" do
      expect { result }.not_to change { server.server_channels.count }
    end

    it "writes the new attributes onto the existing row" do
      result

      expect(existing.reload).to have_attributes(name: "general", position: 2)
    end
  end
end
