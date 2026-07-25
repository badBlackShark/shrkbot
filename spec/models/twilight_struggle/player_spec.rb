# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwilightStruggle::Player do
  describe ".from_payload" do
    subject(:player) { described_class.from_payload(payload) }

    context "with string keys" do
      let(:payload) { {"name" => "Alice", "flag" => "🇺🇸", "discord_id" => "123"} }

      it "builds a Player" do
        expect(player).to eq(described_class.new(name: "Alice", flag: "🇺🇸", discord_id: "123"))
      end
    end

    context "with symbol keys" do
      let(:payload) { {name: "Bob", flag: "🇷🇺", discord_id: "456"} }

      it "builds a Player" do
        expect(player).to eq(described_class.new(name: "Bob", flag: "🇷🇺", discord_id: "456"))
      end
    end

    context "without optional fields" do
      let(:payload) { {name: "Carol"} }

      it "defaults flag and discord_id to nil" do
        expect(player).to eq(described_class.new(name: "Carol"))
      end
    end
  end

  describe "#to_s" do
    subject { player.to_s }

    let(:player) { described_class.new(name: "Alice") }

    it { is_expected.to eq("Alice") }
  end
end
