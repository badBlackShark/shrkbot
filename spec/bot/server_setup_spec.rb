# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServerSetup do
  subject(:handle) { described_class.new(event).handle }

  let(:server) { double("server", id: 77) }
  let(:bot) { double("bot") }
  let(:event) { double("event", server:, bot:) }

  it "syncs the joined server's config and metadata" do
    expect(GuildMetadata).to receive(:sync).with(server, bot)
    handle
  end
end
