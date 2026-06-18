require "rails_helper"

RSpec.describe Reminders::Duration do
  describe ".parse" do
    subject(:parsed) { described_class.parse(input) }

    context "with a multi-unit string" do
      let(:input) { "1d2h30m" }

      it "sums the units into a Duration" do
        expect(parsed).to eq(1.day + 2.hours + 30.minutes)
        expect(parsed).to be_a(ActiveSupport::Duration)
      end
    end

    context "with weeks and days" do
      let(:input) { "2w1d" }
      it { is_expected.to eq(2.weeks + 1.day) }
    end

    context "with a single unit" do
      context "weeks" do
        let(:input) { "2w" }
        it { is_expected.to eq(2.weeks) }
      end

      context "days" do
        let(:input) { "5d" }
        it { is_expected.to eq(5.days) }
      end

      context "hours" do
        let(:input) { "3h" }
        it { is_expected.to eq(3.hours) }
      end

      context "minutes" do
        let(:input) { "90m" }
        it { is_expected.to eq(90.minutes) }
      end

      context "seconds" do
        let(:input) { "45s" }
        it { is_expected.to eq(45.seconds) }
      end
    end

    context "case-insensitively" do
      context "uppercase units" do
        let(:input) { "1D2H" }
        it { is_expected.to eq(1.day + 2.hours) }
      end

      context "mixed case units" do
        let(:input) { "1D2h30M" }
        it { is_expected.to eq(1.day + 2.hours + 30.minutes) }
      end
    end

    context "with surrounding whitespace" do
      context "leading" do
        let(:input) { "  1d" }
        it { is_expected.to eq(1.day) }
      end

      context "trailing" do
        let(:input) { "1d  " }
        it { is_expected.to eq(1.day) }
      end

      context "both sides" do
        let(:input) { "  2h30m  " }
        it { is_expected.to eq(2.hours + 30.minutes) }
      end
    end

    context "with invalid input" do
      context "a blank string" do
        let(:input) { "" }
        it { is_expected.to be_nil }
      end

      context "nil" do
        let(:input) { nil }
        it { is_expected.to be_nil }
      end

      context "non-matching text" do
        let(:input) { "tomorrow" }
        it { is_expected.to be_nil }
      end

      context "text with spaces" do
        let(:input) { "1 day" }
        it { is_expected.to be_nil }
      end

      context "a unit before its number" do
        let(:input) { "d5" }
        it { is_expected.to be_nil }
      end

      context "trailing garbage" do
        let(:input) { "1dgarbage" }
        it { is_expected.to be_nil }
      end

      context "a bad unit character" do
        let(:input) { "1d2x" }
        it { is_expected.to be_nil }
      end
    end

    context "with a zero total" do
      context "'0m'" do
        let(:input) { "0m" }
        it { is_expected.to be_nil }
      end

      context "'0d0h'" do
        let(:input) { "0d0h" }
        it { is_expected.to be_nil }
      end

      context "'0w'" do
        let(:input) { "0w" }
        it { is_expected.to be_nil }
      end
    end

    context "return type" do
      let(:input) { "1d" }
      it { is_expected.to be_a(ActiveSupport::Duration) }
    end
  end
end
