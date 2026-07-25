# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwilightStruggle::GameReport do
  let(:usa) { TwilightStruggle::Player.new(name: "Alice") }
  let(:ussr) { TwilightStruggle::Player.new(name: "Bob") }

  describe ".from_payload" do
    subject(:report) { described_class.from_payload(payload) }

    let(:payload) do
      {
        usa: {name: "Alice"},
        ussr: {name: "Bob"},
        winning_side: "usa",
        winning_turn: 6,
        winning_method: "defcon",
        game_code: "R1",
        game_date: "2026-07-20",
        video_urls: ["https://youtu.be/dQw4w9WgXcQ"]
      }
    end

    it "builds usa as a Player" do
      expect(report.usa).to eq(TwilightStruggle::Player.new(name: "Alice"))
    end

    it "builds ussr as a Player" do
      expect(report.ussr).to eq(TwilightStruggle::Player.new(name: "Bob"))
    end

    it "carries the scalar fields through" do
      expect(report).to have_attributes(
        winning_side: "usa",
        winning_turn: 6,
        winning_method: "defcon",
        game_code: "R1",
        game_date: "2026-07-20",
        video_urls: ["https://youtu.be/dQw4w9WgXcQ"]
      )
    end

    context "without video_urls" do
      let(:payload) { {usa: {name: "Alice"}, ussr: {name: "Bob"}, winning_side: "usa"} }

      it "defaults video_urls to an empty array" do
        expect(report.video_urls).to eq([])
      end
    end
  end

  describe "#tie?" do
    subject { report.tie? }

    context "when winning_side is tie" do
      let(:report) { described_class.new(usa: usa, ussr: ussr, winning_side: "tie") }

      it { is_expected.to be(true) }
    end

    context "when winning_side is usa" do
      let(:report) { described_class.new(usa: usa, ussr: ussr, winning_side: "usa") }

      it { is_expected.to be(false) }
    end
  end

  describe "winner/loser resolution" do
    context "on a usa win" do
      let(:report) { described_class.new(usa: usa, ussr: ussr, winning_side: "usa") }

      it "winner is the usa player" do
        expect(report.winner).to eq(usa)
      end

      it "loser is the ussr player" do
        expect(report.loser).to eq(ussr)
      end

      it "winner_side is :usa" do
        expect(report.winner_side).to eq(:usa)
      end

      it "loser_side is :ussr" do
        expect(report.loser_side).to eq(:ussr)
      end
    end

    context "on a ussr win" do
      let(:report) { described_class.new(usa: usa, ussr: ussr, winning_side: "ussr") }

      it "winner is the ussr player" do
        expect(report.winner).to eq(ussr)
      end

      it "loser is the usa player" do
        expect(report.loser).to eq(usa)
      end

      it "winner_side is :ussr" do
        expect(report.winner_side).to eq(:ussr)
      end

      it "loser_side is :usa" do
        expect(report.loser_side).to eq(:usa)
      end
    end

    context "on a tie" do
      let(:report) { described_class.new(usa: usa, ussr: ussr, winning_side: "tie") }

      it "winner is nil" do
        expect(report.winner).to be_nil
      end

      it "loser is nil" do
        expect(report.loser).to be_nil
      end

      it "winner_side is nil" do
        expect(report.winner_side).to be_nil
      end

      it "loser_side is nil" do
        expect(report.loser_side).to be_nil
      end
    end
  end
end
