# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwilightStruggle::Player do
  describe ".from_payload" do
    subject(:player) { described_class.from_payload(payload) }

    context "with string keys" do
      let(:payload) { {"name" => "Alice", "flag" => "🇺🇸", "discord_id" => "123", "rating_before" => 1500, "rating_after" => 1512} }

      it "builds a Player" do
        expect(player).to eq(described_class.new(name: "Alice", flag: "🇺🇸", discord_id: "123", rating_before: 1500, rating_after: 1512))
      end
    end

    context "with symbol keys" do
      let(:payload) { {name: "Bob", flag: "🇷🇺", discord_id: "456", rating_before: 1500, rating_after: 1488} }

      it "builds a Player" do
        expect(player).to eq(described_class.new(name: "Bob", flag: "🇷🇺", discord_id: "456", rating_before: 1500, rating_after: 1488))
      end
    end

    context "without optional fields" do
      let(:payload) { {name: "Carol"} }

      it "defaults flag and discord_id to nil" do
        expect(player).to eq(described_class.new(name: "Carol"))
      end

      it "defaults rating_before and rating_after to nil" do
        expect(player.rating_before).to be_nil
        expect(player.rating_after).to be_nil
      end
    end
  end

  describe "#to_s" do
    subject { player.to_s }

    let(:player) { described_class.new(name: "Alice") }

    it { is_expected.to eq("Alice") }
  end
end
