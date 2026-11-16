# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::ImageScanning::ScanMessage do
  subject(:scan) { described_class.call(contexts) }

  let(:base) do
    Moderation::ImageScanning::ScanContext.new(
      bot: nil,
      server: nil,
      member: nil,
      channel_id: 3,
      message_id: 4,
      image_url: nil,
      signals: {},
      new_account_age_days: 30,
      settings: nil,
      silent: false
    )
  end
  let(:first) { base.with(image_url: "https://cdn/1.png") }
  let(:second) { base.with(image_url: "https://cdn/2.png") }
  let(:contexts) { [first, second] }
  let(:first_result) { :allow }
  let(:results) { {first.image_url => first_result, second.image_url => :allow} }

  before do
    allow(Moderation::ImageScanning::ScanProcessor).to receive(:call) { |context| results.fetch(context.image_url) }
  end

  it "scans every image of the message in order, loudly" do
    scan
    expect(Moderation::ImageScanning::ScanProcessor).to have_received(:call).with(first).ordered
    expect(Moderation::ImageScanning::ScanProcessor).to have_received(:call).with(second).ordered
  end

  context "when an image is flagged for review" do
    let(:first_result) { :flag_for_review }

    it "scans the remaining images silently, so one message pings staff once" do
      scan
      expect(Moderation::ImageScanning::ScanProcessor).to have_received(:call).with(second.with(silent: true))
    end
  end

  context "when an image is removed" do
    let(:first_result) { :remove }

    it "stops, so the message is acted on once" do
      scan
      expect(Moderation::ImageScanning::ScanProcessor).to have_received(:call).once
    end
  end

  context "when scanning an image crashes" do
    before do
      allow(Moderation::ImageScanning::ScanProcessor).to receive(:call) do |context|
        raise "boom" if context.image_url == first.image_url

        :allow
      end
      allow(Rails.logger).to receive(:error)
    end

    it "logs the crash and still scans the remaining images" do
      scan
      expect(Rails.logger).to have_received(:error).with(/scan crashed on message 4: RuntimeError: boom/)
      expect(Moderation::ImageScanning::ScanProcessor).to have_received(:call).with(second)
    end
  end
end
