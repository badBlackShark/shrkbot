# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::CommandSetup do
  subject(:handle) { described_class.new(event).handle }

  let(:server) { double("server", id: 77) }
  let(:bot) { double("bot") }
  let(:event) { double("event", server:, bot:) }
  let(:syncer) { instance_double(Bot::GuildCommandSync) }

  before do
    allow(Bot::GuildCommandSync).to receive(:new).with(bot).and_return(syncer)
    allow(syncer).to receive(:sync)
  end

  it "syncs commands for the joined server" do
    handle
    expect(syncer).to have_received(:sync).with(77)
  end
end
