# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::ServerConfiguration::ChannelOverwrites::Replace do
  subject(:result) { described_class.call(server_channel: channel, overwrites:) }

  let(:channel) { create(:server_channel) }

  context "when the overwrite is unseen" do
    let(:overwrites) { [{target_id: 555, target_type: "role", allow: 1024, deny: 2048}] }

    it "creates it" do
      expect { result }.to change { channel.channel_overwrites.count }.from(0).to(1)
    end

    it "stores its attributes" do
      result

      expect(channel.channel_overwrites.sole).to have_attributes(target_id: 555, target_type: "role", allow: 1024, deny: 2048)
    end
  end

  context "when the overwrite already exists" do
    let!(:existing) { create(:channel_overwrite, server_channel: channel, target_id: 555, allow: 0, deny: 0) }
    let(:overwrites) { [{target_id: 555, target_type: "role", allow: 1024, deny: 2048}] }

    it "updates it rather than creating a second row" do
      expect { result }.not_to change { channel.channel_overwrites.count }
    end

    it "writes the new attributes onto the existing row" do
      result

      expect(existing.reload).to have_attributes(allow: 1024, deny: 2048)
    end
  end

  context "when a channel loaded fresh from the DB (association not preloaded) has an overwrite no longer present upstream" do
    let!(:stale) { create(:channel_overwrite, server_channel: channel, target_id: 777) }
    let(:overwrites) { [] }

    it "prunes the stale overwrite" do
      expect(channel.channel_overwrites).not_to be_loaded

      result

      expect(ChannelOverwrite.where(id: stale.id)).to be_empty
    end
  end

  context "when the caller reports the channel was just created" do
    subject(:result) { described_class.call(server_channel: channel, overwrites:, created: true) }

    let(:overwrites) { [{target_id: 555, target_type: "role", allow: 1024, deny: 2048}] }

    it "writes the overwrites without looking for rows that cannot exist yet" do
      expect { result }.to change { channel.channel_overwrites.count }.from(0).to(1)
    end
  end

  context "when the incoming list matches the channel's existing overwrites" do
    let!(:existing) { create(:channel_overwrite, server_channel: channel, target_id: 555, target_type: "role", allow: 1024, deny: 2048) }
    let(:overwrites) { [{target_id: 555, target_type: "role", allow: 1024, deny: 2048}] }

    it "leaves the row untouched" do
      expect { result }.not_to change { existing.reload.updated_at }
    end
  end
end
