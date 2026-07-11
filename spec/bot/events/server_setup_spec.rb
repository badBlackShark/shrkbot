# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::ServerSetup do
  subject(:handle) { described_class.new(event).handle }

  let(:server) { double("server", id: 77) }
  let(:bot) { double("bot") }
  let(:event) { double("event", server:, bot:) }

  it "syncs the joined server's config and metadata" do
    expect(Bot::GuildMetadata).to receive(:sync).with(server, bot)
    handle
  end
end
