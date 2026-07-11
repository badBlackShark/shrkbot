# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::ImageScanning::PhashIndex do
  subject(:index) { described_class.new }

  let(:own_guild) { create(:server_configuration, discord_id: 111) }
  let(:foreign_guild) { create(:server_configuration, discord_id: 222) }
  let(:stored_hex) { "00000000000000ff" }

  describe "#lookup" do
    context "when the own guild confirmed the phash" do
      before do
        create(:phash_confirmation, phash: create(:phash, phash: stored_hex), server_configuration: own_guild, verdict: "confirmed")
      end

      it "returns :own_confirmed" do
        expect(index.lookup(stored_hex, own_guild.discord_id)).to eq(:own_confirmed)
      end
    end

    context "when the own guild dismissed the phash" do
      before do
        create(:phash_confirmation, phash: create(:phash, phash: stored_hex), server_configuration: own_guild, verdict: "dismissed")
      end

      it "returns :own_dismissed" do
        expect(index.lookup(stored_hex, own_guild.discord_id)).to eq(:own_dismissed)
      end
    end

    context "when only a foreign guild confirmed the phash" do
      before do
        create(:phash_confirmation, phash: create(:phash, phash: stored_hex), server_configuration: foreign_guild, verdict: "confirmed")
      end

      it "returns :foreign_confirmed" do
        expect(index.lookup(stored_hex, own_guild.discord_id)).to eq(:foreign_confirmed)
      end
    end

    context "when only a foreign guild dismissed the phash" do
      before do
        create(:phash_confirmation, phash: create(:phash, phash: stored_hex), server_configuration: foreign_guild, verdict: "dismissed")
      end

      it "returns :none" do
        expect(index.lookup(stored_hex, own_guild.discord_id)).to eq(:none)
      end
    end

    context "when no phash matches" do
      before do
        create(:phash_confirmation, phash: create(:phash, phash: stored_hex), server_configuration: own_guild, verdict: "confirmed")
      end

      it "returns :none" do
        expect(index.lookup("ffffffff00000000", own_guild.discord_id)).to eq(:none)
      end
    end

    context "when the queried hex matches exactly" do
      before do
        create(:phash_confirmation, phash: create(:phash, phash: stored_hex), server_configuration: own_guild, verdict: "confirmed")
      end

      it "matches" do
        expect(index.lookup(stored_hex, own_guild.discord_id)).to eq(:own_confirmed)
      end
    end

    context "when the queried hex is within the Hamming threshold" do
      let(:near_hex) { "00000000000000f0" }

      before do
        create(:phash_confirmation, phash: create(:phash, phash: stored_hex), server_configuration: own_guild, verdict: "confirmed")
      end

      it "matches (Hamming distance 4)" do
        expect(Moderation::SimHash.hamming_distance(stored_hex.to_i(16), near_hex.to_i(16))).to eq(4)
        expect(index.lookup(near_hex, own_guild.discord_id)).to eq(:own_confirmed)
      end
    end

    context "when the queried hex is beyond the Hamming threshold" do
      let(:far_hex) { "00000000000000e0" }

      before do
        create(:phash_confirmation, phash: create(:phash, phash: stored_hex), server_configuration: own_guild, verdict: "confirmed")
      end

      it "does not match (Hamming distance 5)" do
        expect(Moderation::SimHash.hamming_distance(stored_hex.to_i(16), far_hex.to_i(16))).to eq(5)
        expect(index.lookup(far_hex, own_guild.discord_id)).to eq(:none)
      end
    end

    context "when own and foreign guilds disagree" do
      before do
        phash = create(:phash, phash: stored_hex)
        create(:phash_confirmation, phash:, server_configuration: foreign_guild, verdict: "confirmed")
        create(:phash_confirmation, phash:, server_configuration: own_guild, verdict: "dismissed")
      end

      it "takes the own verdict over the foreign one" do
        expect(index.lookup(stored_hex, own_guild.discord_id)).to eq(:own_dismissed)
      end
    end

    context "called repeatedly within the refresh interval" do
      before do
        create(:phash_confirmation, phash: create(:phash, phash: stored_hex), server_configuration: own_guild, verdict: "confirmed")
      end

      it "reuses the cached snapshot instead of rebuilding" do
        index.lookup(stored_hex, own_guild.discord_id)
        expect(index.lookup(stored_hex, own_guild.discord_id)).to eq(:own_confirmed)
      end
    end
  end

  describe "#invalidate" do
    before do
      create(:phash_confirmation, phash: create(:phash, phash: stored_hex), server_configuration: own_guild, verdict: "confirmed")
    end

    it "forces a reload so a DB change is visible on the next lookup" do
      index.lookup(stored_hex, own_guild.discord_id)

      Moderation::PhashConfirmation.where(server_configuration: own_guild).update_all(verdict: "dismissed")

      index.invalidate

      expect(index.lookup(stored_hex, own_guild.discord_id)).to eq(:own_dismissed)
    end

    it "keeps the stale result if invalidate is NOT called" do
      index.lookup(stored_hex, own_guild.discord_id)

      Moderation::PhashConfirmation.where(server_configuration: own_guild).update_all(verdict: "dismissed")

      expect(index.lookup(stored_hex, own_guild.discord_id)).to eq(:own_confirmed)
    end
  end

  describe ".instance" do
    it "memoizes a single process-wide index" do
      expect(described_class.instance).to be_a(described_class)
      expect(described_class.instance).to equal(described_class.instance)
    end
  end

  describe ".lookup" do
    before do
      create(:phash_confirmation, phash: create(:phash, phash: stored_hex), server_configuration: own_guild, verdict: "confirmed")
    end

    it "delegates to the singleton instance" do
      expect(described_class.lookup(stored_hex, own_guild.discord_id)).to eq(:own_confirmed)
    end
  end
end
