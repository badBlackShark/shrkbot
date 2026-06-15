require "rails_helper"

RSpec.describe Reminders::Duration do
  describe ".parse" do
    context "with valid multi-unit strings" do
      it "parses '1d2h30m' correctly" do
        result = Reminders::Duration.parse("1d2h30m")
        expect(result).to eq(1.day + 2.hours + 30.minutes)
        expect(result).to be_a(ActiveSupport::Duration)
      end

      it "parses '2w1d' correctly" do
        result = Reminders::Duration.parse("2w1d")
        expect(result).to eq(2.weeks + 1.day)
      end
    end

    context "with single units" do
      it "parses weeks" do
        expect(Reminders::Duration.parse("2w")).to eq(2.weeks)
      end

      it "parses days" do
        expect(Reminders::Duration.parse("5d")).to eq(5.days)
      end

      it "parses hours" do
        expect(Reminders::Duration.parse("3h")).to eq(3.hours)
      end

      it "parses minutes" do
        expect(Reminders::Duration.parse("90m")).to eq(90.minutes)
      end

      it "parses seconds" do
        expect(Reminders::Duration.parse("45s")).to eq(45.seconds)
      end
    end

    context "with case-insensitivity" do
      it "parses uppercase units" do
        expect(Reminders::Duration.parse("1D2H")).to eq(1.day + 2.hours)
      end

      it "parses mixed case units" do
        expect(Reminders::Duration.parse("1D2h30M")).to eq(1.day + 2.hours + 30.minutes)
      end
    end

    context "with whitespace handling" do
      it "trims leading whitespace" do
        expect(Reminders::Duration.parse("  1d")).to eq(1.day)
      end

      it "trims trailing whitespace" do
        expect(Reminders::Duration.parse("1d  ")).to eq(1.day)
      end

      it "trims both sides" do
        expect(Reminders::Duration.parse("  2h30m  ")).to eq(2.hours + 30.minutes)
      end
    end

    context "with invalid input" do
      it "returns nil for blank string" do
        expect(Reminders::Duration.parse("")).to be_nil
      end

      it "returns nil for nil input" do
        expect(Reminders::Duration.parse(nil)).to be_nil
      end

      it "returns nil for non-matching text" do
        expect(Reminders::Duration.parse("tomorrow")).to be_nil
      end

      it "returns nil for text with spaces" do
        expect(Reminders::Duration.parse("1 day")).to be_nil
      end

      it "returns nil for invalid unit format" do
        expect(Reminders::Duration.parse("d5")).to be_nil
      end

      it "returns nil for trailing garbage" do
        expect(Reminders::Duration.parse("1dgarbage")).to be_nil
      end

      it "returns nil for bad unit character" do
        expect(Reminders::Duration.parse("1d2x")).to be_nil
      end
    end

    context "with zero totals" do
      it "returns nil for '0m'" do
        expect(Reminders::Duration.parse("0m")).to be_nil
      end

      it "returns nil for '0d0h'" do
        expect(Reminders::Duration.parse("0d0h")).to be_nil
      end

      it "returns nil for '0w'" do
        expect(Reminders::Duration.parse("0w")).to be_nil
      end
    end

    context "return type validation" do
      it "returns an ActiveSupport::Duration for valid input" do
        result = Reminders::Duration.parse("1d")
        expect(result).to be_a(ActiveSupport::Duration)
      end
    end
  end
end
