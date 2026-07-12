# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::ImageScanning::EnqueueScan do
  subject(:call) { described_class.call(event:, images:) }

  let(:guild_id) { 111 }
  let(:author_id) { 222 }

  let(:server) { double("server", id: guild_id) }
  let(:author) { double("author", id: author_id) }
  let(:message) { double("message", id: 1, webhook?: false, content: "hello") }
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

  before do
    allow(server).to receive(:owner).and_return(owner)
    allow(Moderation::ImageScanning::Settings).to receive(:active_for).with(guild_id).and_return(settings)
    allow(Moderation::ImageScanning::Signals).to receive(:call).and_return(signals)
    allow(Moderation::ImageScanning::ScanQueue).to receive(:enqueue)
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

    it "enqueues one processor" do
      expect(Moderation::ImageScanning::ScanQueue).to receive(:enqueue).with(kind_of(Proc)).once
      call
    end

    it "builds a ScanContext with image_url" do
      captured_context = nil
      allow(Moderation::ImageScanning::ScanQueue).to receive(:enqueue) do |proc|
        allow(Moderation::ImageScanning::ScanProcessor).to receive(:call) do |ctx|
          captured_context = ctx
        end
        proc.call
      end

      call

      expect(captured_context.image_url).to eq("https://cdn/x.png")
    end
  end

  context "with multiple images" do
    let(:images) { ["https://cdn/a.png", "https://cdn/b.png"] }

    it "enqueues one processor per image" do
      expect(Moderation::ImageScanning::ScanQueue).to receive(:enqueue).with(kind_of(Proc)).exactly(2).times
      call
    end
  end

  context "when the author is a regular member with a staff role configured" do
    let(:staff_role_id) { 444 }
    let(:author) { double("author", id: author_id, roles: []) }

    it "enqueues normally" do
      expect(Moderation::ImageScanning::ScanQueue).to receive(:enqueue).with(kind_of(Proc)).once
      call
    end
  end
end
