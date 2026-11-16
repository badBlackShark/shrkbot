# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::ImageScan do
  subject(:handle) { described_class.new(event).handle }

  let(:message) { double("message") }
  let(:event) { double("event", message:) }
  let(:image_urls) { ["https://cdn/x.png", "https://cdn/fwd.png"] }

  before do
    allow(Moderation::ImageScanning::ScannableImages).to receive(:on_create).with(message).and_return(image_urls)
    allow(Moderation::ImageScanning::EnqueueScan).to receive(:call)
  end

  it "registers on :message" do
    expect(described_class.discord_events).to include(:message)
  end

  it "delegates to EnqueueScan with every image the new message carries" do
    expect(Moderation::ImageScanning::EnqueueScan).to receive(:call).with(
      event:,
      images: image_urls
    )
    handle
  end
end
