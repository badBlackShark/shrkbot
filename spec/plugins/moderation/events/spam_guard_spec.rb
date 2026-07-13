# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::SpamGuard do
  subject(:handle) { described_class.new(event).handle }

  let(:guild_id) { 111 }
  let(:author_id) { 222 }
  let(:staff_role_id) { 333 }
  let(:log_channel_id) { 444 }

  let(:owner) { double("owner", id: 999) }
  let(:server) { double("server", id: guild_id, owner:) }
  let(:author) { double("author", id: author_id, roles: []) }
  let(:message) { double("message", id: 1, webhook?: false, content: "hello world foo bar", attachments: []) }
  let(:channel) { double("channel", id: 1, pm?: false) }
  let(:log_channel) { double("log_channel") }
  let(:bot) { double("bot") }
  let(:event) { double("event", from_bot?: false, server:, author:, message:, channel:, bot:) }

  let(:logging_setting) { double("logging_setting", channel_id: log_channel_id) }
  let(:ping_staff) { true }
  let(:moderation_settings) { double("moderation_settings", staff_role_id:, ping_staff:) }
  let(:config) do
    double(
      "server_configuration",
      logging_setting:,
      moderation_settings:
    )
  end
  let(:action) { "purge" }
  let(:punishment) { "none" }
  let(:match_symbol_only_messages) { false }
  let(:settings) do
    double(
      "spam_protection_settings",
      server_configuration: config,
      channel_threshold: 3,
      window_seconds: 60,
      similarity: 1.0,
      action:,
      action_purge?: action == "purge",
      punishment:,
      punishment_none?: punishment == "none",
      punishment_timeout?: punishment == "timeout",
      timeout_seconds: 300,
      match_symbol_only_messages:
    )
  end

  let(:tracker) { Moderation::SpamTracker.new }

  before do
    allow(Moderation::SpamProtection::Settings).to receive(:active_for).with(guild_id).and_return(settings)
    allow(Moderation::SpamTracker).to receive(:instance).and_return(tracker)
    allow(bot).to receive(:channel).with(log_channel_id).and_return(log_channel)
  end

  def simulate_message(channel_id:, message_id:, content: "hello world foo bar", attachments: [])
    msg = double("message_#{message_id}", id: message_id, webhook?: false, content:, attachments:)
    ch = double("channel_#{channel_id}", id: channel_id, pm?: false)
    evt = double("event_#{message_id}", from_bot?: false, server:, author:, message: msg, channel: ch, bot:)
    described_class.new(evt).handle
  end

  context "when spam protection is inactive" do
    before { allow(Moderation::SpamProtection::Settings).to receive(:active_for).and_return(nil) }

    it "does nothing" do
      expect(bot).not_to receive(:channel)
      handle
    end
  end

  context "when message is from bot" do
    before { allow(event).to receive(:from_bot?).and_return(true) }

    it "skips processing" do
      expect(Moderation::SpamProtection::Settings).not_to receive(:active_for)
      handle
    end
  end

  context "when message is a webhook" do
    before { allow(message).to receive(:webhook?).and_return(true) }

    it "skips processing" do
      expect(Moderation::SpamProtection::Settings).not_to receive(:active_for)
      handle
    end
  end

  context "when channel is a DM" do
    before { allow(channel).to receive(:pm?).and_return(true) }

    it "skips processing" do
      expect(Moderation::SpamProtection::Settings).not_to receive(:active_for)
      handle
    end
  end

  context "when author has staff role" do
    let(:staff_role) { double("role", id: staff_role_id) }
    let(:author) { double("author", id: author_id, roles: [staff_role]) }

    it "does not purge or notify" do
      expect(bot).not_to receive(:channel)
      handle
    end
  end

  context "when author is the server owner" do
    let(:author) { double("author", id: 999, roles: []) }

    it "does not purge or notify" do
      expect(bot).not_to receive(:channel)
      handle
    end
  end

  context "when below threshold" do
    it "does not purge or notify" do
      simulate_message(channel_id: 1, message_id: 1)
      expect(bot).not_to receive(:channel).with(log_channel_id)
      simulate_message(channel_id: 1, message_id: 2)
    end
  end

  context "when threshold reached across channels with action 'purge'" do
    before do
      allow(bot).to receive(:channel).with(1).and_return(double("ch1", delete_message: nil))
      allow(bot).to receive(:channel).with(2).and_return(double("ch2", delete_message: nil))
      allow(bot).to receive(:channel).with(3).and_return(double("ch3", delete_message: nil))
      allow(Bot::Discord::Components).to receive(:send_to)
    end

    it "deletes each hit message and sends a notification" do
      expect(bot.channel(1)).to receive(:delete_message).with(10)
      expect(bot.channel(2)).to receive(:delete_message).with(20)
      expect(bot.channel(3)).to receive(:delete_message).with(30)
      expect(Bot::Discord::Components).to receive(:send_to).with(
        log_channel,
        anything,
        allowed_mentions: hash_including(roles: array_including(staff_role_id)),
        attachments: nil
      )

      simulate_message(channel_id: 1, message_id: 10)
      simulate_message(channel_id: 2, message_id: 20)
      simulate_message(channel_id: 3, message_id: 30)
    end

    it "includes the window and the quoted message content in the notification" do
      body = nil
      allow(Bot::Discord::Components).to receive(:send_to) do |_channel, rendered, **|
        body = rendered[:components].first[:components].first[:content]
      end

      simulate_message(channel_id: 1, message_id: 10)
      simulate_message(channel_id: 2, message_id: 20)
      simulate_message(channel_id: 3, message_id: 30)

      expect(body).to include("within 60 seconds")
      expect(body).to include("> hello world foo bar")
    end

    it "notes that no member punishment was taken when punishment is 'none'" do
      body = nil
      allow(Bot::Discord::Components).to receive(:send_to) do |_channel, rendered, **|
        body = rendered[:components].first[:components].first[:content]
      end

      simulate_message(channel_id: 1, message_id: 10)
      simulate_message(channel_id: 2, message_id: 20)
      simulate_message(channel_id: 3, message_id: 30)

      expect(body).to include("No further action was taken.")
    end

    context "when the punishment is a timeout" do
      let(:punishment) { "timeout" }

      before { allow(Moderation::Punisher).to receive(:call) }

      it "notes the timeout with an absolute Discord timestamp" do
        body = nil
        allow(Bot::Discord::Components).to receive(:send_to) do |_channel, rendered, **|
          body = rendered[:components].first[:components].first[:content]
        end

        simulate_message(channel_id: 1, message_id: 10)
        simulate_message(channel_id: 2, message_id: 20)
        simulate_message(channel_id: 3, message_id: 30)

        expect(body).to match(/User was timed out until <t:\d+:f>\./)
      end
    end

    context "when a followup message lands inside the hot window" do
      let(:ch4) { double("ch4", delete_message: nil) }

      before do
        allow(bot).to receive(:channel).with(4).and_return(ch4)
      end

      it "deletes the followup and posts a followup log entry" do
        simulate_message(channel_id: 1, message_id: 10)
        simulate_message(channel_id: 2, message_id: 20)
        simulate_message(channel_id: 3, message_id: 30)

        expect(ch4).to receive(:delete_message).with(40)
        expect(Bot::Discord::Components).to receive(:send_to) do |_channel, rendered, **|
          body = rendered[:components].first[:components].first[:content]
          expect(body).to include("Cross-channel spam follow-up removed")
          expect(body).to include("<#4>")
        end

        simulate_message(channel_id: 4, message_id: 40)
      end
    end
  end

  context "when a followup lands with action 'notify_only'" do
    let(:action) { "notify_only" }
    let(:ch4) { double("ch4") }

    before do
      allow(bot).to receive(:channel).with(4).and_return(ch4)
      allow(Bot::Discord::Components).to receive(:send_to)
    end

    it "neither deletes nor logs the followup" do
      simulate_message(channel_id: 1, message_id: 10)
      simulate_message(channel_id: 2, message_id: 20)
      simulate_message(channel_id: 3, message_id: 30)

      expect(ch4).not_to receive(:delete_message)
      expect(Bot::Discord::Components).not_to receive(:send_to)

      simulate_message(channel_id: 4, message_id: 40)
    end
  end

  context "when action is 'notify_only'" do
    let(:action) { "notify_only" }
    let(:ch1) { double("ch1") }
    let(:ch2) { double("ch2") }
    let(:ch3) { double("ch3") }

    before do
      allow(bot).to receive(:channel).with(1).and_return(ch1)
      allow(bot).to receive(:channel).with(2).and_return(ch2)
      allow(bot).to receive(:channel).with(3).and_return(ch3)
      allow(Bot::Discord::Components).to receive(:send_to)
    end

    it "sends notification but does not delete messages" do
      expect(ch1).not_to receive(:delete_message)
      expect(ch2).not_to receive(:delete_message)
      expect(ch3).not_to receive(:delete_message)
      expect(Bot::Discord::Components).to receive(:send_to)

      simulate_message(channel_id: 1, message_id: 1)
      simulate_message(channel_id: 2, message_id: 2)
      simulate_message(channel_id: 3, message_id: 3)
    end
  end

  context "with match_symbol_only_messages false" do
    it "does not trigger on punctuation-only messages across channels" do
      expect(Bot::Discord::Components).not_to receive(:send_to)

      simulate_message(channel_id: 1, message_id: 1, content: "!!!")
      simulate_message(channel_id: 2, message_id: 2, content: "???")
      simulate_message(channel_id: 3, message_id: 3, content: "...")
      simulate_message(channel_id: 4, message_id: 4, content: "---")
    end
  end

  context "with match_symbol_only_messages true" do
    let(:match_symbol_only_messages) { true }

    before do
      allow(bot).to receive(:channel).and_return(double("ch", delete_message: nil))
      allow(Bot::Discord::Components).to receive(:send_to)
    end

    it "triggers on mixed punctuation-only messages across channels (all blank after canonicalization)" do
      expect(Bot::Discord::Components).to receive(:send_to)

      simulate_message(channel_id: 1, message_id: 1, content: "!!!")
      simulate_message(channel_id: 2, message_id: 2, content: "???")
      simulate_message(channel_id: 3, message_id: 3, content: "...")
    end
  end

  context "when the same attachment is posted across channels" do
    let(:attachment) { double("attachment", filename: "scam.png", size: 1024, url: "https://cdn/scam.png") }

    before do
      allow(bot).to receive(:channel).and_return(double("ch", delete_message: nil))
      allow(Bot::Discord::Components).to receive(:send_to)
      allow(Moderation::AttachmentDownload).to receive(:call).and_return("IMG")
    end

    it "fingerprints attachments and triggers on the threshold" do
      expect(Bot::Discord::Components).to receive(:send_to)

      simulate_message(channel_id: 1, message_id: 1, content: "", attachments: [attachment])
      simulate_message(channel_id: 2, message_id: 2, content: "", attachments: [attachment])
      simulate_message(channel_id: 3, message_id: 3, content: "", attachments: [attachment])
    end
  end

  context "when the same bytes are posted under randomized filenames" do
    let(:attachment1) { double("attachment1", filename: "abc123.png", size: 1024, url: "https://cdn/file.png") }
    let(:attachment2) { double("attachment2", filename: "xyz789.png", size: 1024, url: "https://cdn/file.png") }
    let(:attachment3) { double("attachment3", filename: "qwe456.png", size: 1024, url: "https://cdn/file.png") }

    before do
      allow(bot).to receive(:channel).and_return(double("ch", delete_message: nil))
      allow(Bot::Discord::Components).to receive(:send_to)
      allow(Moderation::AttachmentDownload).to receive(:call).and_return("same bytes")
    end

    it "produces the same SHA256 fingerprint and triggers on the threshold" do
      expect(Bot::Discord::Components).to receive(:send_to)

      simulate_message(channel_id: 1, message_id: 1, content: "", attachments: [attachment1])
      simulate_message(channel_id: 2, message_id: 2, content: "", attachments: [attachment2])
      simulate_message(channel_id: 3, message_id: 3, content: "", attachments: [attachment3])
    end
  end

  context "when a message has more than MAX_HASHED_ATTACHMENTS attachments" do
    let(:attachments) do
      Array.new(4) { |i| double("attachment#{i}", filename: "f#{i}.png", size: 1024, url: "https://cdn/#{i}.png") }
    end

    before do
      allow(bot).to receive(:channel).and_return(double("ch", delete_message: nil))
      allow(Bot::Discord::Components).to receive(:send_to)
      allow(Moderation::AttachmentDownload).to receive(:call).and_return("bytes")
    end

    it "downloads only the first three and filename-fingerprints the rest" do
      expect(Moderation::AttachmentDownload).to receive(:call).exactly(3).times

      simulate_message(channel_id: 1, message_id: 1, content: "", attachments:)
    end
  end

  context "when the attachment download fails" do
    let(:attachment) { double("attachment", filename: "scam.png", size: 1024, url: "https://cdn/scam.png") }

    before do
      allow(bot).to receive(:channel).and_return(double("ch", delete_message: nil))
      allow(Bot::Discord::Components).to receive(:send_to)
      allow(Moderation::AttachmentDownload).to receive(:call).and_raise(Moderation::AttachmentDownload::Error)
    end

    it "falls back to filename+size fingerprint and still triggers on the threshold" do
      expect(Bot::Discord::Components).to receive(:send_to)

      simulate_message(channel_id: 1, message_id: 1, content: "", attachments: [attachment])
      simulate_message(channel_id: 2, message_id: 2, content: "", attachments: [attachment])
      simulate_message(channel_id: 3, message_id: 3, content: "", attachments: [attachment])
    end
  end

  context "when the attachment exceeds MAX_FINGERPRINT_BYTES" do
    let(:oversize) { 11 * 1024 * 1024 }
    let(:attachment) { double("attachment", filename: "big.png", size: oversize, url: "https://cdn/big.png") }

    before do
      allow(bot).to receive(:channel).and_return(double("ch", delete_message: nil))
      allow(Bot::Discord::Components).to receive(:send_to)
    end

    it "does not download and falls back to filename+size fingerprint, still triggering" do
      expect(Moderation::AttachmentDownload).not_to receive(:call)
      expect(Bot::Discord::Components).to receive(:send_to)

      simulate_message(channel_id: 1, message_id: 1, content: "", attachments: [attachment])
      simulate_message(channel_id: 2, message_id: 2, content: "", attachments: [attachment])
      simulate_message(channel_id: 3, message_id: 3, content: "", attachments: [attachment])
    end
  end

  context "when a source channel is missing or deletion fails" do
    before do
      allow(bot).to receive(:channel).with(1).and_return(double("ch1", delete_message: nil))
      allow(bot).to receive(:channel).with(2).and_return(nil)
      allow(bot).to receive(:channel).with(3).and_raise(RuntimeError, "forbidden")
      allow(Bot::Discord::Components).to receive(:send_to)
    end

    it "skips the missing channel, logs the failure, and still notifies" do
      expect(Bot::Discord::Components).to receive(:send_to)

      simulate_message(channel_id: 1, message_id: 10)
      simulate_message(channel_id: 2, message_id: 20)
      expect { simulate_message(channel_id: 3, message_id: 30) }.not_to raise_error
    end
  end

  context "when the log channel is unset" do
    let(:action) { "notify_only" }
    let(:logging_setting) { double("logging_setting", channel_id: nil) }

    it "does not attempt to notify" do
      expect(Bot::Discord::Components).not_to receive(:send_to)

      simulate_message(channel_id: 1, message_id: 1)
      simulate_message(channel_id: 2, message_id: 2)
      simulate_message(channel_id: 3, message_id: 3)
    end
  end

  context "when the log channel no longer exists" do
    let(:action) { "notify_only" }

    before do
      allow(bot).to receive(:channel).with(log_channel_id).and_return(nil)
    end

    it "does not attempt to notify" do
      expect(Bot::Discord::Components).not_to receive(:send_to)

      simulate_message(channel_id: 1, message_id: 1)
      simulate_message(channel_id: 2, message_id: 2)
      simulate_message(channel_id: 3, message_id: 3)
    end
  end

  context "when the notification send fails" do
    let(:action) { "notify_only" }

    before do
      allow(Bot::Discord::Components).to receive(:send_to).and_raise(RuntimeError, "no perms")
    end

    it "rescues and does not raise into the handler" do
      simulate_message(channel_id: 1, message_id: 1)
      simulate_message(channel_id: 2, message_id: 2)
      expect { simulate_message(channel_id: 3, message_id: 3) }.not_to raise_error
    end
  end

  context "when ping_staff is false" do
    let(:action) { "notify_only" }
    let(:ping_staff) { false }

    before do
      allow(bot).to receive(:channel).with(1).and_return(double("ch1", delete_message: nil))
      allow(bot).to receive(:channel).with(2).and_return(double("ch2", delete_message: nil))
      allow(bot).to receive(:channel).with(3).and_return(double("ch3", delete_message: nil))
      allow(Bot::Discord::Components).to receive(:send_to)
    end

    it "notifies with empty roles in allowed_mentions" do
      expect(Bot::Discord::Components).to receive(:send_to).with(
        log_channel,
        anything,
        allowed_mentions: {parse: [], roles: []},
        attachments: nil
      )

      simulate_message(channel_id: 1, message_id: 10)
      simulate_message(channel_id: 2, message_id: 20)
      simulate_message(channel_id: 3, message_id: 30)
    end

    it "does not start the body with a role mention" do
      body = nil
      allow(Bot::Discord::Components).to receive(:send_to) do |_channel, rendered, **|
        body = rendered[:components].first[:components].first[:content]
      end

      simulate_message(channel_id: 1, message_id: 10)
      simulate_message(channel_id: 2, message_id: 20)
      simulate_message(channel_id: 3, message_id: 30)

      expect(body).not_to start_with("<@&")
    end
  end

  context "when no staff role is configured" do
    let(:action) { "notify_only" }
    let(:moderation_settings) { double("moderation_settings", staff_role_id: nil, ping_staff: true) }

    before do
      allow(Bot::Discord::Components).to receive(:send_to)
    end

    it "notifies with an empty roles array (seam guard prevents this in production)" do
      expect(Bot::Discord::Components).to receive(:send_to).with(
        log_channel,
        anything,
        allowed_mentions: {parse: [], roles: []},
        attachments: nil
      )

      simulate_message(channel_id: 1, message_id: 1)
      simulate_message(channel_id: 2, message_id: 2)
      simulate_message(channel_id: 3, message_id: 3)
    end
  end

  context "when punishment is set" do
    let(:action) { "notify_only" }
    let(:punishment) { "kick" }

    before do
      allow(Bot::Discord::Components).to receive(:send_to)
    end

    it "invokes Punisher.call on threshold hit" do
      expect(Moderation::Punisher).to receive(:call).with(
        member: author,
        server:,
        punishment: "kick",
        timeout_seconds: 300,
        reason: "Cross-channel spam"
      )

      simulate_message(channel_id: 1, message_id: 1)
      simulate_message(channel_id: 2, message_id: 2)
      simulate_message(channel_id: 3, message_id: 3)
    end

    it "notes the kick in the notification body" do
      allow(Moderation::Punisher).to receive(:call)
      body = nil
      allow(Bot::Discord::Components).to receive(:send_to) do |_channel, rendered, **|
        body = rendered[:components].first[:components].first[:content]
      end

      simulate_message(channel_id: 1, message_id: 1)
      simulate_message(channel_id: 2, message_id: 2)
      simulate_message(channel_id: 3, message_id: 3)

      expect(body).to include("User was kicked.")
    end
  end
end
