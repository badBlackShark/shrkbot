# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::ImageScanning::EnqueueScan do
  subject(:call) { described_class.call(event:, images:) }

  let(:guild_id) { 111 }
  let(:author_id) { 222 }

  let(:server) { double("server", id: guild_id) }
  let(:author) { double("author", id: author_id) }
  let(:message) { double("message", id: 1, webhook?: false, content: "hello", snapshots:) }
  let(:snapshots) { [] }
  let(:channel) { double("channel", id: 1, pm?: false) }
  let(:bot) { double("bot") }
  let(:event) { double("event", from_bot?: false, server:, author:, message:, channel:, bot:) }

  let(:owner) { double("owner", id: 999) }
  let(:staff_role_id) { nil }
  let(:moderation_settings) { double("moderation_settings", staff_role_id:, new_account_age_days: 30) }
  let(:server_configuration) { double("server_configuration", moderation_settings:) }
  let(:settings) { double("settings", server_configuration:) }
  let(:signals) { {account_age_days: 2, has_link: false, has_role: false} }

  let(:images) { ["https://cdn/x.png"] }
  let(:captured) { [] }

  before do
    allow(server).to receive(:owner).and_return(owner)
    allow(Moderation::ImageScanning::Settings).to receive(:active_for).with(guild_id).and_return(settings)
    allow(Moderation::ImageScanning::Signals).to receive(:call).and_return(signals)
    allow(Moderation::ImageScanning::ScanQueue).to receive(:enqueue)
  end

  shared_context "when the queued job runs" do
    before do
      allow(Moderation::ImageScanning::ScanMessage).to receive(:call) { |contexts| captured.concat(contexts) }
      allow(Moderation::ImageScanning::ScanQueue).to receive(:enqueue) { |_author_id, job| job.call }
    end
  end

  context "when the event is from a bot" do
    before { allow(event).to receive(:from_bot?).and_return(true) }

    it "skips processing without hitting the DB" do
      expect(Moderation::ImageScanning::Settings).not_to receive(:active_for)
      expect(Moderation::ImageScanning::ScanQueue).not_to receive(:enqueue)
      call
    end
  end

  context "when the message is a webhook" do
    before { allow(message).to receive(:webhook?).and_return(true) }

    it "skips processing without hitting the DB" do
      expect(Moderation::ImageScanning::Settings).not_to receive(:active_for)
      expect(Moderation::ImageScanning::ScanQueue).not_to receive(:enqueue)
      call
    end
  end

  context "when the channel is a DM" do
    before { allow(channel).to receive(:pm?).and_return(true) }

    it "skips processing without hitting the DB" do
      expect(Moderation::ImageScanning::Settings).not_to receive(:active_for)
      expect(Moderation::ImageScanning::ScanQueue).not_to receive(:enqueue)
      call
    end
  end

  context "when images list is empty" do
    let(:images) { [] }

    it "does not hit the DB and does not enqueue" do
      expect(Moderation::ImageScanning::Settings).not_to receive(:active_for)
      expect(Moderation::ImageScanning::ScanQueue).not_to receive(:enqueue)
      call
    end
  end

  context "when image scanning is inactive" do
    before { allow(Moderation::ImageScanning::Settings).to receive(:active_for).and_return(nil) }

    it "does not enqueue" do
      expect(Moderation::ImageScanning::ScanQueue).not_to receive(:enqueue)
      call
    end
  end

  context "when the author is the server owner" do
    let(:author) { double("author", id: owner.id, roles: []) }

    it "does not enqueue" do
      expect(Moderation::ImageScanning::ScanQueue).not_to receive(:enqueue)
      call
    end
  end

  context "when the author holds the staff role" do
    let(:staff_role_id) { 444 }
    let(:staff_role) { double("role", id: staff_role_id) }
    let(:author) { double("author", id: author_id, roles: [staff_role]) }

    it "does not enqueue" do
      expect(Moderation::ImageScanning::ScanQueue).not_to receive(:enqueue)
      call
    end
  end

  context "with a single image and a regular member" do
    it "computes signals with author, content, and server_id" do
      expect(Moderation::ImageScanning::Signals).to receive(:call).with(
        author:,
        content: "hello",
        server_id: guild_id
      ).and_return(signals)
      call
    end

    context "when the message forwards text that holds a link" do
      let(:snapshots) { [double("snapshot", content: "see https://x.example")] }

      it "computes signals over the forwarded text too" do
        expect(Moderation::ImageScanning::Signals).to receive(:call).with(
          author:,
          content: "hello\nsee https://x.example",
          server_id: guild_id
        ).and_return(signals)
        call
      end
    end

    it "enqueues one job" do
      expect(Moderation::ImageScanning::ScanQueue).to receive(:enqueue).with(author_id, kind_of(Proc)).once
      call
    end

    context "when the queued job runs" do
      include_context "when the queued job runs"

      it "builds a ScanContext with image_url" do
        call
        expect(captured.map(&:image_url)).to eq(["https://cdn/x.png"])
      end

      it "starts every image as not silent" do
        call
        expect(captured.map(&:silent)).to eq([false])
      end
    end
  end

  context "with multiple images" do
    let(:images) { ["https://cdn/a.png", "https://cdn/b.png"] }

    it "enqueues one job for the whole message" do
      expect(Moderation::ImageScanning::ScanQueue).to receive(:enqueue).with(author_id, kind_of(Proc)).once
      call
    end

    context "when the queued job runs" do
      include_context "when the queued job runs"

      it "hands every image to ScanMessage in order" do
        call
        expect(captured.map(&:image_url)).to eq(["https://cdn/a.png", "https://cdn/b.png"])
      end
    end
  end

  context "when the author is a regular member with a staff role configured" do
    let(:staff_role_id) { 444 }
    let(:author) { double("author", id: author_id, roles: []) }

    it "enqueues normally" do
      expect(Moderation::ImageScanning::ScanQueue).to receive(:enqueue).with(author_id, kind_of(Proc)).once
      call
    end
  end
end
