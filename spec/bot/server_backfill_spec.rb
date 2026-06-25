# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServerBackfill do
  subject(:handle) { described_class.new(event).handle }

  let(:server_a) { double("server", id: 111) }
  let(:server_b) { double("server", id: 222) }
  let(:bot) { double("bot", servers: {111 => server_a, 222 => server_b}) }
  let(:event) { double("event", bot:) }

  it "syncs every server the bot is already in" do
    expect(GuildMetadata).to receive(:sync).with(server_a, bot)
    expect(GuildMetadata).to receive(:sync).with(server_b, bot)
    handle
  end
end
