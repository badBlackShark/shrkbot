require "rails_helper"

RSpec.describe OwnerNotifier do
  let(:pm_channel) { double("pm_channel", send_message: nil) }
  let(:bot) { double("bot", pm_channel:) }
  let(:error) { RuntimeError.new("boom").tap { |e| e.set_backtrace(["a.rb:1", "b.rb:2"]) } }

  describe ".report" do
    subject(:report) { described_class.report(bot:, error:, source:) }

    let(:source) { "command /ping" }

    before do
      allow(BotSetting).to receive(:owner_error_dms?).and_return(dms_enabled)
      allow(BotConfig).to receive(:owner_id).and_return(owner_id)
    end

    context "when the toggle is on and an owner is configured" do
      let(:dms_enabled) { true }
      let(:owner_id) { "4242" }

      it "DMs the owner the formatted error" do
        expect(bot).to receive(:pm_channel).with(4242).and_return(pm_channel)
        expect(pm_channel).to receive(:send_message).with(a_string_including("RuntimeError", "boom", "command /ping"))
        report
      end
    end

    context "when the toggle is off" do
      let(:dms_enabled) { false }
      let(:owner_id) { "4242" }

      it "does nothing" do
        expect(bot).not_to receive(:pm_channel)
        report
      end
    end

    context "when no owner is configured" do
      let(:dms_enabled) { true }
      let(:owner_id) { nil }

      it "does nothing" do
        expect(bot).not_to receive(:pm_channel)
        report
      end
    end

    context "when the DM fails" do
      let(:dms_enabled) { true }
      let(:owner_id) { "4242" }

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
      allow(BotConfig).to receive(:owner_id).and_return(owner_id)
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
      expect(formatted.length).to be <= OwnerNotifier::MAX_LENGTH + 1
    end
  end
end
