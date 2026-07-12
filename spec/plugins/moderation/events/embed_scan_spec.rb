# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::EmbedScan do
  subject(:handle) { described_class.new(event).handle }

  let(:message) { double("message") }
  let(:event) { double("event", message:) }
  let(:embed_urls) { ["https://media.discordapp.net/a.png"] }

  before do
    allow(Moderation::ImageScanning::ScannableImages).to receive(:embeds).with(message).and_return(embed_urls)
    allow(Moderation::ImageScanning::EnqueueScan).to receive(:call)
  end

  it "registers on :message_update" do
    expect(described_class.discord_events).to include(:message_update)
  end

  it "delegates to EnqueueScan with embed image URLs" do
    expect(Moderation::ImageScanning::EnqueueScan).to receive(:call).with(
      event:,
      images: embed_urls
    )
    handle
  end
end
