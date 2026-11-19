# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::RouteLabels do
  subject(:labels) { described_class.new(server) }

  let(:server) { create(:server_configuration) }

  before do
    create(:server_channel, server_configuration: server, name: "news", channel_type: 4, discord_id: 10)
    create(:server_channel, server_configuration: server, name: "patches", channel_type: 0, discord_id: 11, parent_id: 10)
    create(:server_role, server_configuration: server, name: "Streams", discord_id: 20)
    create(:server_role, server_configuration: server, name: "@everyone", discord_id: 21)
  end

  describe "#channel" do
    it "is the qualified channel name" do
      expect(labels.channel(11)).to eq("news / #patches")
    end

    it "is nil for a channel that no longer exists" do
      expect(labels.channel(99)).to be_nil
    end
  end

  describe "#channel_text" do
    it "falls back to the deleted-channel text" do
      expect(labels.channel_text(99)).to eq("channel deleted")
    end
  end

  describe "#role_text" do
    it "mentions the role by name" do
      expect(labels.role_text(20)).to eq("@Streams")
    end

    it "does not double the @ of @everyone" do
      expect(labels.role_text(21)).to eq("@everyone")
    end

    it "falls back to the deleted-role text" do
      expect(labels.role_text(99)).to eq("a role that was deleted")
    end
  end

  it "loads roles only when a role is asked for" do
    allow(ServerRoleOptions).to receive(:new).and_call_original

    labels.channel_text(11)

    expect(ServerRoleOptions).not_to have_received(:new)
  end

  it "loads each list once however many labels it hands out" do
    allow(ServerRoleOptions).to receive(:new).and_call_original
    allow(ChannelOptions).to receive(:new).and_call_original

    2.times do
      labels.role_text(20)
      labels.channel(11)
    end

    expect(ServerRoleOptions).to have_received(:new).once
    expect(ChannelOptions).to have_received(:new).once
  end
end
