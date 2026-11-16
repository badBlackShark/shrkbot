# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::ImageScanning::ScanMessage do
  subject(:scan) { described_class.call(contexts) }

  let(:first) { double("first context", message_id: 4) }
  let(:second) { double("second context") }
  let(:contexts) { [first, second] }
  let(:first_result) { :allow }

  before do
    allow(Moderation::ImageScanning::ScanProcessor).to receive(:call).with(first).and_return(first_result)
    allow(Moderation::ImageScanning::ScanProcessor).to receive(:call).with(second).and_return(:allow)
  end

  it "scans every image of the message in order" do
    scan
    expect(Moderation::ImageScanning::ScanProcessor).to have_received(:call).with(first).ordered
    expect(Moderation::ImageScanning::ScanProcessor).to have_received(:call).with(second).ordered
  end

  context "when an image is flagged for review" do
    let(:first_result) { :flag_for_review }

    it "keeps scanning the remaining images" do
      scan
      expect(Moderation::ImageScanning::ScanProcessor).to have_received(:call).with(second)
    end
  end

  context "when an image is removed" do
    let(:first_result) { :remove }

    it "stops, so the message is acted on once" do
      scan
      expect(Moderation::ImageScanning::ScanProcessor).not_to have_received(:call).with(second)
    end
  end

  context "when scanning an image crashes" do
    before do
      allow(Moderation::ImageScanning::ScanProcessor).to receive(:call).with(first).and_raise(RuntimeError, "boom")
      allow(Rails.logger).to receive(:error)
    end

    it "logs the crash and still scans the remaining images" do
      scan
      expect(Rails.logger).to have_received(:error).with(/scan crashed on message 4: RuntimeError: boom/)
      expect(Moderation::ImageScanning::ScanProcessor).to have_received(:call).with(second)
    end
  end
end
