# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::ImageScan do
  subject(:handle) { described_class.new(event).handle }

  let(:message) { double("message") }
  let(:event) { double("event", message:) }
  let(:attachment_urls) { ["https://cdn/x.png"] }
  let(:content_link_urls) { ["https://cdn.discordapp.com/attachments/1/2/img.png"] }

  before do
    allow(Moderation::ImageScanning::ScannableImages).to receive(:attachments).with(message).and_return(attachment_urls)
    allow(Moderation::ImageScanning::ScannableImages).to receive(:content_links).with(message).and_return(content_link_urls)
    allow(Moderation::ImageScanning::EnqueueScan).to receive(:call)
  end

  it "registers on :message" do
    expect(described_class.discord_events).to include(:message)
  end

  it "delegates to EnqueueScan with attachment URLs and content link URLs combined" do
    expect(Moderation::ImageScanning::EnqueueScan).to receive(:call).with(
      event:,
      images: attachment_urls + content_link_urls
    )
    handle
  end
end
