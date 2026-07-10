# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::VerdictExecutor do
  let(:image_bytes) { "fakepngbytes" }
  subject(:execute) { described_class.call(verdict:, context:, phash:, image_bytes:) }

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
      action_delete?: settings_action == "delete",
      punishment:,
      punishment_none?: punishment == "none",
      timeout_seconds: 300,
      sensitivity: "standard",
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

  let(:phash) { "0123456789abcdef" }
  let(:action) { :remove }
  let(:reasons) do
    [
      Moderation::Reason.new(key: :new_account, weight: 2, detail: 3),
      Moderation::Reason.new(key: :rule, weight: 3, detail: "promo code")
    ]
  end
  let(:verdict) { Moderation::Verdict.new(action:, risk: 5.0, reasons:) }

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

    it "logs the image with the flagged title, an FileUpload, and the staff role in allowed_mentions" do
      execute

      expect(ActivityLog).to have_received(:post).with(
        server_configuration,
        hash_including(
          title: I18n.t("moderation.image_scanning.flag.title.flagged"),
          allowed_mentions: {parse: [], roles: [staff_role_id]}
        )
      ) do |_config, kwargs|
        io = kwargs[:image]
        expect(io).to be_a(Discord::FileUpload)
        expect(io.path).to eq("x.png")
        expect(io.original_filename).to eq("x.png")
        io.rewind
        expect(io.read).to eq(image_bytes)
      end
    end

    it "does not delete or punish" do
      expect(bot).not_to receive(:channel)
      expect(Moderation::Punisher).not_to receive(:call)
      execute
    end

    it "posts a confirm/dismiss action row carrying the phash custom_ids" do
      execute

      expect(ActivityLog).to have_received(:post) do |_config, kwargs|
        row = kwargs[:components].first
        expect(row[:type]).to eq(Discord::Components::ACTION_ROW)
        custom_ids = row[:components].map { |button| button[:custom_id] }
        expect(custom_ids).to eq(["mod:confirm:#{phash}", "mod:dismiss:#{phash}"])
      end
    end

    it "includes a colon after the staff role ping in the body" do
      execute

      expect(ActivityLog).to have_received(:post) do |_config, kwargs|
        expect(kwargs[:body]).to include("<@&#{staff_role_id}>: ")
      end
    end

    it "has locale copy for every classifier reason key" do
      keys = %i[rule custom_keywords new_account has_link no_role own_confirmed foreign_confirmed]
      keys.each do |key|
        expect(I18n.exists?("moderation.image_scanning.flag.reasons.#{key}")).to be(true)
      end
    end

    context "with keyword, foreign-hash, and fractional-risk reasons" do
      let(:reasons) do
        [
          Moderation::Reason.new(key: :custom_keywords, weight: 4, detail: 2),
          Moderation::Reason.new(key: :foreign_confirmed, weight: 0),
          Moderation::Reason.new(key: :no_role, weight: 0.5)
        ]
      end
      let(:verdict) { Moderation::Verdict.new(action:, risk: 4.5, reasons:) }

      it "renders the keyword count, omits the weight on zero-weight reasons, and keeps fractions" do
        execute

        expect(ActivityLog).to have_received(:post) do |_config, kwargs|
          body = kwargs[:body]
          expect(body).to include("Risk `4.5` of the `3` needed for a flag:")
          expect(body).to include("- matched 2 custom keywords (`+4`)")
          expect(body).to include("- matches an image confirmed as a scam on another server\n")
          expect(body).to include("(`+0.5`)")
          expect(body).not_to include("(`+0`)")
        end
      end
    end

    it "includes a risk line with backticked numbers in the body" do
      execute

      expect(ActivityLog).to have_received(:post) do |_config, kwargs|
        expect(kwargs[:body]).to match(/Risk `5` of the `3` needed for a flag:/)
      end
    end

    it "includes reason bullets in the body" do
      execute

      expect(ActivityLog).to have_received(:post) do |_config, kwargs|
        expect(kwargs[:body]).to include("(`+2`)")
        expect(kwargs[:body]).to include('matched "promo code"')
        expect(kwargs[:body]).to include("(`+3`)")
      end
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

    it "includes a risk line for removal in the body" do
      execute

      expect(ActivityLog).to have_received(:post) do |_config, kwargs|
        expect(kwargs[:body]).to match(/Risk `5` of the `6` needed for removal:/)
      end
    end

    it "posts a confirm/dismiss action row carrying the phash custom_ids" do
      execute

      expect(ActivityLog).to have_received(:post) do |_config, kwargs|
        row = kwargs[:components].first
        expect(row[:type]).to eq(Discord::Components::ACTION_ROW)
        custom_ids = row[:components].map { |button| button[:custom_id] }
        expect(custom_ids).to eq(["mod:confirm:#{phash}", "mod:dismiss:#{phash}"])
      end
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
