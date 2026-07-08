# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::VerdictExecutor do
  subject(:execute) { described_class.call(verdict:, context:) }

  let(:server_id) { 111 }
  let(:member_id) { 222 }
  let(:staff_role_id) { 333 }
  let(:channel_id) { 444 }
  let(:message_id) { 555 }
  let(:attachment_url) { "https://cdn/x.png" }

  let(:server) { double("server", id: server_id) }
  let(:member) { double("member", id: member_id) }
  let(:message_channel) { double("message_channel", delete_message: nil) }
  let(:bot) { double("bot", channel: message_channel) }

  let(:logging_setting) { double("logging_setting", channel_id: channel_id) }
  let(:moderation_settings) { double("moderation_settings", staff_role_id:) }
  let(:server_configuration) do
    double(
      "server_configuration",
      logging_setting:,
      moderation_settings:
    )
  end

  let(:settings_action) { "delete" }
  let(:punishment) { "none" }
  let(:settings) do
    double(
      "settings",
      action: settings_action,
      punishment:,
      timeout_seconds: 300,
      server_configuration:
    )
  end

  let(:context) do
    Moderation::ScanContext.new(
      bot:,
      server:,
      member:,
      channel_id:,
      message_id:,
      attachment_url:,
      signals: {},
      settings:
    )
  end

  let(:action) { :remove }
  let(:verdict) { Moderation::Verdict.new(action:, risk: 7.0, reasons: [:new_account, "usdt"]) }

  before do
    allow(ActivityLog).to receive(:post)
    allow(Moderation::Punisher).to receive(:call)
  end

  context "when the action is :allow" do
    let(:action) { :allow }

    it "does not log, delete, or punish" do
      expect(ActivityLog).not_to receive(:post)
      expect(bot).not_to receive(:channel)
      expect(Moderation::Punisher).not_to receive(:call)
      execute
    end
  end

  context "when the action is :flag_for_review" do
    let(:action) { :flag_for_review }

    it "logs the image with the flagged title and the staff role in allowed_mentions" do
      execute

      expect(ActivityLog).to have_received(:post).with(
        server_configuration,
        hash_including(
          title: I18n.t("moderation.image_scanning.flag.title.flagged"),
          image_url: attachment_url,
          allowed_mentions: {parse: [], roles: [staff_role_id]}
        )
      )
    end

    it "does not delete or punish" do
      expect(bot).not_to receive(:channel)
      expect(Moderation::Punisher).not_to receive(:call)
      execute
    end
  end

  context "when the action is :remove with settings.action 'delete'" do
    let(:settings_action) { "delete" }

    it "deletes the message and logs the removed title" do
      execute

      expect(bot).to have_received(:channel).with(channel_id)
      expect(message_channel).to have_received(:delete_message).with(message_id)
      expect(ActivityLog).to have_received(:post).with(
        server_configuration,
        hash_including(title: I18n.t("moderation.image_scanning.flag.title.removed"))
      )
    end

    context "when the message channel no longer exists" do
      let(:bot) { double("bot", channel: nil) }

      it "does not raise and still logs" do
        expect { execute }.not_to raise_error
        expect(ActivityLog).to have_received(:post)
      end
    end

    context "when deleting the message fails" do
      before do
        allow(message_channel).to receive(:delete_message).and_raise(RuntimeError, "forbidden")
      end

      it "rescues the failure and still logs" do
        expect { execute }.not_to raise_error
        expect(ActivityLog).to have_received(:post)
      end
    end
  end

  context "when the action is :remove with settings.action 'none'" do
    let(:settings_action) { "none" }
    let(:punishment) { "kick" }

    it "does not delete but still logs the removed title" do
      expect(bot).not_to receive(:channel)
      execute

      expect(ActivityLog).to have_received(:post).with(
        server_configuration,
        hash_including(title: I18n.t("moderation.image_scanning.flag.title.removed"))
      )
    end

    it "runs the punish path" do
      execute

      expect(Moderation::Punisher).to have_received(:call).with(
        member:,
        server:,
        punishment: "kick",
        timeout_seconds: 300,
        reason: I18n.t("moderation.image_scanning.punishment.reason")
      )
    end
  end

  context "when the punishment is 'none'" do
    let(:punishment) { "none" }

    it "does not invoke the punisher" do
      expect(Moderation::Punisher).not_to receive(:call)
      execute
    end
  end

  context "when no staff role is configured" do
    let(:staff_role_id) { nil }

    it "logs with empty roles" do
      execute

      expect(ActivityLog).to have_received(:post).with(
        server_configuration,
        hash_including(allowed_mentions: {parse: [], roles: []})
      )
    end
  end
end
