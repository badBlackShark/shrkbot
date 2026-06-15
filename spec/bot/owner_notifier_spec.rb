require "rails_helper"

RSpec.describe OwnerNotifier do
  let(:pm_channel) { double("pm_channel", send_message: nil) }
  let(:bot) { double("bot", pm_channel: pm_channel) }
  let(:error) { RuntimeError.new("boom").tap { |e| e.set_backtrace(["a.rb:1", "b.rb:2"]) } }

  describe ".report" do
    context "when the toggle is on and an owner is configured" do
      before do
        allow(Setting).to receive(:owner_error_dms?).and_return(true)
        allow(BotConfig).to receive(:owner_id).and_return("4242")
      end

      it "DMs the owner the formatted error" do
        expect(bot).to receive(:pm_channel).with(4242).and_return(pm_channel)
        expect(pm_channel).to receive(:send_message).with(a_string_including("RuntimeError", "boom", "command /ping"))

        described_class.report(bot:, error:, source: "command /ping")
      end
    end

    it "does nothing when the toggle is off" do
      allow(Setting).to receive(:owner_error_dms?).and_return(false)
      allow(BotConfig).to receive(:owner_id).and_return("4242")
      expect(bot).not_to receive(:pm_channel)

      described_class.report(bot:, error:, source: "x")
    end

    it "does nothing when no owner is configured" do
      allow(Setting).to receive(:owner_error_dms?).and_return(true)
      allow(BotConfig).to receive(:owner_id).and_return(nil)
      expect(bot).not_to receive(:pm_channel)

      described_class.report(bot:, error:, source: "x")
    end

    it "swallows DM failures so they never mask the original error" do
      allow(Setting).to receive(:owner_error_dms?).and_return(true)
      allow(BotConfig).to receive(:owner_id).and_return("4242")
      allow(bot).to receive(:pm_channel).and_raise(StandardError, "discord down")

      expect { described_class.report(bot:, error:, source: "x") }.not_to raise_error
    end
  end

  describe ".format_message" do
    it "truncates to Discord's limit" do
      huge = RuntimeError.new("x" * 5000)
      expect(described_class.format_message(huge, "src").length).to be <= OwnerNotifier::MAX_LENGTH + 1
    end
  end
end
