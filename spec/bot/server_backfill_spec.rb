require "rails_helper"

RSpec.describe ServerBackfill do
  subject(:handle) { described_class.new(event).handle }

  let(:servers) { {111 => double(id: 111), 222 => double(id: 222)} }
  let(:bot) { double("bot", servers:) }
  let(:event) { double("event", bot:) }

  it "ensures a configuration for every server the bot is already in" do
    expect(Ops::ServerConfiguration::Ensure).to receive(:call).with(discord_id: 111)
    expect(Ops::ServerConfiguration::Ensure).to receive(:call).with(discord_id: 222)
    handle
  end
end
