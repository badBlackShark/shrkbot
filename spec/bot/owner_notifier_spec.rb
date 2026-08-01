# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::OwnerNotifier do
  let(:pm_channel) { double("pm_channel", send_message: nil) }
  let(:bot) { double("bot", pm_channel:) }
  let(:error) { RuntimeError.new("boom").tap { |e| e.set_backtrace(["a.rb:1", "b.rb:2"]) } }
  let(:throttle) { Bot::ErrorThrottle.new }

  before do
    allow(Bot::ErrorThrottle).to receive(:instance).and_return(throttle)
  end

  describe ".report" do
    subject(:report) { described_class.report(bot:, error:, source:) }

    let(:source) { "command /ping" }
    let(:dms_enabled) { true }
    let(:owner_id) { "4242" }

    before do
      allow(BotSetting).to receive(:owner_error_dms?).and_return(dms_enabled)
      allow(Bot::Config).to receive(:owner_id).and_return(owner_id)
    end

    context "when the toggle is on and an owner is configured" do
      it "DMs the owner the formatted error" do
        expect(bot).to receive(:pm_channel).with(4242).and_return(pm_channel)
        expect(pm_channel).to receive(:send_message).with(a_string_including("RuntimeError", "boom", "command /ping"))
        report
      end
    end

    context "when the same error repeats inside the throttle window" do
      before { described_class.report(bot:, error:, source:) }

      it "DMs the owner once instead of once per occurrence" do
        expect(pm_channel).not_to receive(:send_message)
        10.times { described_class.report(bot:, error:, source:) }
      end
    end

    context "when the throttle admits a report after suppressing others" do
      before { allow(throttle).to receive(:admit).and_return(3) }

      it "tells the owner how many occurrences were suppressed" do
        expect(pm_channel).to receive(:send_message).with(a_string_including("plus 3 more"))
        report
      end
    end

    context "when a different error hits the same source" do
      before { described_class.report(bot:, error: RuntimeError.new("first"), source:) }

      it "is not throttled, since it is a distinct failure" do
        expect(pm_channel).to receive(:send_message).with(a_string_including("ArgumentError"))
        described_class.report(bot:, error: ArgumentError.new("second"), source:)
      end
    end

    context "when the toggle is off" do
      let(:dms_enabled) { false }

      it "does nothing" do
        expect(bot).not_to receive(:pm_channel)
        report
      end
    end

    context "when no owner is configured" do
      let(:owner_id) { nil }

      it "does nothing" do
        expect(bot).not_to receive(:pm_channel)
        report
      end
    end

    context "when the DM fails" do
      before do
        allow(bot).to receive(:pm_channel).and_raise(StandardError, "discord down")
      end

      it "swallows the failure so it never masks the original error" do
        expect { report }.not_to raise_error
      end
    end
  end

  describe ".notify" do
    subject(:notify) { described_class.notify(bot:, message: "your channel was deleted") }

    before do
      allow(Bot::Config).to receive(:owner_id).and_return(owner_id)
    end

    context "with an owner configured" do
      let(:owner_id) { "4242" }

      it "DMs the owner the message regardless of the error-DM toggle" do
        allow(BotSetting).to receive(:owner_error_dms?).and_return(false)
        expect(bot).to receive(:pm_channel).with(4242).and_return(pm_channel)
        expect(pm_channel).to receive(:send_message).with("your channel was deleted")
        notify
      end
    end

    context "without an owner configured" do
      let(:owner_id) { nil }

      it "does nothing" do
        expect(bot).not_to receive(:pm_channel)
        notify
      end
    end
  end

  describe ".format_message" do
    subject(:formatted) { described_class.format_message(error, "src") }

    let(:error) { RuntimeError.new("x" * 5000) }

    it "truncates to Discord's limit" do
      expect(formatted.length).to be <= Bot::OwnerNotifier::MAX_LENGTH + 1
    end
  end
end
