# frozen_string_literal: true

require "rails_helper"

RSpec.describe CommandBackfill do
  subject(:handle) { described_class.new(event).handle }

  let(:bot) { double("bot", servers: {111 => double("s1"), 222 => double("s2")}) }
  let(:event) { double("event", bot:) }
  let(:syncer) { instance_double(GuildCommandSync) }

  before do
    allow(GuildCommandSync).to receive(:new).with(bot).and_return(syncer)
    allow(syncer).to receive(:sync)
  end

  it "syncs every server the bot knows about" do
    handle
    expect(syncer).to have_received(:sync).with(111)
    expect(syncer).to have_received(:sync).with(222)
  end
end
