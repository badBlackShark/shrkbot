# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::ImageScan do
  subject(:handle) { described_class.new(event).handle }

  let(:guild_id) { 111 }
  let(:author_id) { 222 }

  let(:server) { double("server", id: guild_id) }
  let(:author) { double("author", id: author_id) }
  let(:attachments) { [image_attachment] }
  let(:message) { double("message", id: 1, webhook?: false, content: "hello", attachments:) }
  let(:channel) { double("channel", id: 1, pm?: false) }
  let(:bot) { double("bot") }
  let(:event) { double("event", from_bot?: false, server:, author:, message:, channel:, bot:) }

  let(:owner) { double("owner", id: 999) }
  let(:staff_role_id) { nil }
  let(:moderation_settings) { double("moderation_settings", staff_role_id:, new_account_age_days: 30) }
  let(:server_configuration) { double("server_configuration", moderation_settings:) }
  let(:settings) { double("settings", server_configuration:) }
  let(:signals) { {account_age_days: 2, has_link: false, has_role: false} }

  let(:image_attachment) { double("att", content_type: "image/png", size: 1234, url: "https://cdn/x.png") }

  before do
    allow(server).to receive(:owner).and_return(owner)
    allow(Moderation::ImageScanning::Settings).to receive(:active_for).with(guild_id).and_return(settings)
    allow(Moderation::ImageScanning::Signals).to receive(:call).and_return(signals)
    allow(Moderation::ImageScanning::ScanQueue).to receive(:enqueue)
  end

  context "when the message is from a bot" do
    before { allow(event).to receive(:from_bot?).and_return(true) }

    it "skips processing" do
      expect(Moderation::ImageScanning::Settings).not_to receive(:active_for)
      expect(Moderation::ImageScanning::ScanQueue).not_to receive(:enqueue)
      handle
    end
  end

  context "when the message is a webhook" do
    before { allow(message).to receive(:webhook?).and_return(true) }

    it "skips processing" do
      expect(Moderation::ImageScanning::Settings).not_to receive(:active_for)
      expect(Moderation::ImageScanning::ScanQueue).not_to receive(:enqueue)
      handle
    end
  end

  context "when the channel is a DM" do
    before { allow(channel).to receive(:pm?).and_return(true) }

    it "skips processing" do
      expect(Moderation::ImageScanning::Settings).not_to receive(:active_for)
      expect(Moderation::ImageScanning::ScanQueue).not_to receive(:enqueue)
      handle
    end
  end

  context "when image scanning is inactive" do
    before { allow(Moderation::ImageScanning::Settings).to receive(:active_for).and_return(nil) }

    it "does not enqueue" do
      expect(Moderation::ImageScanning::ScanQueue).not_to receive(:enqueue)
      handle
    end
  end

  context "when there are no image attachments" do
    let(:attachments) { [] }

    it "does not enqueue" do
      expect(Moderation::ImageScanning::ScanQueue).not_to receive(:enqueue)
      handle
    end
  end

  context "when an attachment has a non-image content type" do
    let(:attachments) { [double("att", content_type: "application/pdf", size: 1234, url: "https://cdn/x.pdf")] }

    it "skips it and does not enqueue" do
      expect(Moderation::ImageScanning::ScanQueue).not_to receive(:enqueue)
      handle
    end
  end

  context "when an attachment is oversized" do
    let(:attachments) do
      [double("att", content_type: "image/png", size: 11 * 1024 * 1024, url: "https://cdn/big.png")]
    end

    it "skips it and does not enqueue" do
      expect(Moderation::ImageScanning::ScanQueue).not_to receive(:enqueue)
      handle
    end
  end

  context "when there are more eligible attachments than the cap" do
    let(:attachments) do
      Array.new(5) { |i| double("att#{i}", content_type: "image/png", size: 1234, url: "https://cdn/#{i}.png") }
    end

    it "enqueues at most MAX_ATTACHMENTS processors" do
      expect(Moderation::ImageScanning::ScanQueue).to receive(:enqueue).with(kind_of(Proc)).exactly(3).times
      handle
    end
  end

  context "with a single valid image" do
    it "computes signals and enqueues one processor" do
      expect(Moderation::ImageScanning::Signals).to receive(:call).with(author:, content: "hello", server_id: guild_id).and_return(signals)
      expect(Moderation::ImageScanning::ScanQueue).to receive(:enqueue).with(kind_of(Proc)).once
      handle
    end
  end

  context "when the message author is the server owner" do
    let(:author) { double("author", id: owner.id, roles: []) }

    it "does not enqueue" do
      expect(Moderation::ImageScanning::ScanQueue).not_to receive(:enqueue)
      handle
    end
  end

  context "when the message author holds the staff role" do
    let(:staff_role_id) { 444 }
    let(:staff_role) { double("role", id: staff_role_id) }
    let(:author) { double("author", id: author_id, roles: [staff_role]) }

    it "does not enqueue" do
      expect(Moderation::ImageScanning::ScanQueue).not_to receive(:enqueue)
      handle
    end
  end

  context "when the message author is a regular member" do
    let(:staff_role_id) { 444 }
    let(:author) { double("author", id: author_id, roles: []) }

    it "enqueues normally" do
      expect(Moderation::ImageScanning::ScanQueue).to receive(:enqueue).with(kind_of(Proc)).once
      handle
    end
  end
end
