# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwilightStruggle::PlayerRating do
  subject(:rating) { described_class.new(player) }

  describe "#before" do
    subject { rating.before }

    context "with a whole-number integer rating" do
      let(:player) { TwilightStruggle::Player.new(name: "Alice", rating_before: 1512) }

      it { is_expected.to eq("1512") }
    end

    context "with a whole-number float rating" do
      let(:player) { TwilightStruggle::Player.new(name: "Alice", rating_before: 1512.0) }

      it { is_expected.to eq("1512") }
    end

    context "with a fractional rating" do
      let(:player) { TwilightStruggle::Player.new(name: "Alice", rating_before: 1512.5) }

      it { is_expected.to eq("1512.5") }
    end

    context "with a negative rating" do
      let(:player) { TwilightStruggle::Player.new(name: "Alice", rating_before: -12) }

      it { is_expected.to eq("-12") }
    end

    context "with a nil player" do
      let(:player) { nil }

      it { is_expected.to eq("") }
    end

    context "without a rating_before" do
      let(:player) { TwilightStruggle::Player.new(name: "Alice") }

      it { is_expected.to eq("") }
    end
  end

  describe "#after" do
    subject { rating.after }

    context "with a whole-number integer rating" do
      let(:player) { TwilightStruggle::Player.new(name: "Alice", rating_after: 1524) }

      it { is_expected.to eq("1524") }
    end

    context "with a whole-number float rating" do
      let(:player) { TwilightStruggle::Player.new(name: "Alice", rating_after: 1524.0) }

      it { is_expected.to eq("1524") }
    end

    context "with a fractional rating" do
      let(:player) { TwilightStruggle::Player.new(name: "Alice", rating_after: 1524.5) }

      it { is_expected.to eq("1524.5") }
    end

    context "with a negative rating" do
      let(:player) { TwilightStruggle::Player.new(name: "Alice", rating_after: -12) }

      it { is_expected.to eq("-12") }
    end

    context "with a nil player" do
      let(:player) { nil }

      it { is_expected.to eq("") }
    end

    context "without a rating_after" do
      let(:player) { TwilightStruggle::Player.new(name: "Alice") }

      it { is_expected.to eq("") }
    end
  end

  describe "#change" do
    subject { rating.change }

    context "with a nil player" do
      let(:player) { nil }

      it { is_expected.to eq("") }
    end

    context "without a rating_before" do
      let(:player) { TwilightStruggle::Player.new(name: "Alice", rating_after: 1512) }

      it { is_expected.to eq("") }
    end

    context "without a rating_after" do
      let(:player) { TwilightStruggle::Player.new(name: "Alice", rating_before: 1500) }

      it { is_expected.to eq("") }
    end

    context "on a rise" do
      let(:player) { TwilightStruggle::Player.new(name: "Alice", rating_before: 1500, rating_after: 1512) }

      it { is_expected.to eq("+12") }
    end

    context "on a fall" do
      let(:player) { TwilightStruggle::Player.new(name: "Alice", rating_before: 1500, rating_after: 1488) }

      it { is_expected.to eq("-12") }
    end

    context "with no change" do
      let(:player) { TwilightStruggle::Player.new(name: "Alice", rating_before: 1500, rating_after: 1500) }

      it { is_expected.to eq("+0") }
    end

    context "with float subtraction noise" do
      let(:player) { TwilightStruggle::Player.new(name: "Alice", rating_before: 1200.2, rating_after: 1234.7) }

      it { is_expected.to eq("+34.5") }
    end

    context "with negative ratings on both ends" do
      let(:player) { TwilightStruggle::Player.new(name: "Alice", rating_before: -20, rating_after: -8) }

      it { is_expected.to eq("+12") }
    end
  end
end
