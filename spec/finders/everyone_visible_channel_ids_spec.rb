# frozen_string_literal: true

require "rails_helper"

RSpec.describe Finders::EveryoneVisibleChannelIds do
  subject(:ids) { described_class.for(config) }

  let(:config) { create(:server_configuration, discord_id: 42) }
  let!(:open_channel) { create(:server_channel, server_configuration: config, name: "open") }
  let!(:hidden_channel) { create(:server_channel, server_configuration: config, name: "hidden") }
  let!(:voice_channel) { create(:server_channel, server_configuration: config, name: "voice", channel_type: 2) }

  before do
    create(:channel_overwrite, server_channel: hidden_channel, target_id: 42, deny: ServerChannel::VIEW_CHANNEL | 1)
  end

  it "lists the text channels @everyone can see and leaves out hidden and non-text ones" do
    expect(ids).to eq([open_channel.discord_id])
  end

  it "asks the database once, however many channels and overwrites there are" do
    create_list(:server_channel, 3, server_configuration: config).each do |channel|
      create(:channel_overwrite, server_channel: channel, target_id: 42, deny: ServerChannel::VIEW_CHANNEL)
    end
    statements = []
    collector = ->(*, payload) { statements << payload[:sql] unless payload[:name] == "SCHEMA" }

    ActiveSupport::Notifications.subscribed(collector, "sql.active_record") { ids }

    expect(statements.size).to eq(1)
  end

  context "when @everyone has an overwrite that does not touch VIEW_CHANNEL" do
    before do
      create(:channel_overwrite, server_channel: open_channel, target_id: 42, deny: 1 << 11)
    end

    it "keeps the channel" do
      expect(ids).to include(open_channel.discord_id)
    end
  end

  context "when a channel has several overwrites and only another role is denied VIEW_CHANNEL" do
    before do
      create(:channel_overwrite, server_channel: open_channel, target_id: 999, deny: ServerChannel::VIEW_CHANNEL)
      create(:channel_overwrite, server_channel: open_channel, target_id: 42, allow: ServerChannel::VIEW_CHANNEL, deny: 0)
    end

    it "keeps the channel" do
      expect(ids).to include(open_channel.discord_id)
    end
  end

  context "when another server hides a channel from its own @everyone" do
    let(:other) { create(:server_configuration, discord_id: 43) }

    before do
      other_channel = create(:server_channel, server_configuration: other)
      create(:channel_overwrite, server_channel: other_channel, target_id: 43, deny: ServerChannel::VIEW_CHANNEL)
    end

    it "does not list that server's channels" do
      expect(ids).to eq([open_channel.discord_id])
    end
  end
end
