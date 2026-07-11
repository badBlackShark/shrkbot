# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::ImageScanning::FuzzyMatcher do
  describe ".match?" do
    fixture = JSON.parse(File.read(Rails.root.join("spec/fixtures/fuzzy_vectors.json")))

    fixture.each do |vector|
      description = vector["note"] || "#{vector["pattern"].inspect} vs #{vector["text"].inspect} → #{vector["expected"]}"

      it description do
        pattern = vector["regex"] ? Regexp.new(vector["pattern"]) : vector["pattern"]

        expect(described_class.match?(pattern, vector["text"], ratio: vector["ratio"])).to eq(vector["expected"])
      end
    end

    context "exact substring" do
      it "returns true without computing distance" do
        expect(described_class.match?("code", "promo code here")).to be(true)
      end
    end

    context "single edit within tolerance" do
      it "matches a one-character typo" do
        expect(described_class.match?("tuzawin", "visit tuzowin now", ratio: 0.2)).to be(true)
      end
    end

    context "distance exceeds tolerance" do
      it "rejects too many edits" do
        expect(described_class.match?("withdrawal", "xxxxxxxxxx", ratio: 0.2)).to be(false)
      end
    end

    context "regex pattern" do
      it "delegates to Regexp#match?" do
        expect(described_class.match?(/\bbet\b/, "place your bet now")).to be(true)
      end
    end

    context "ratio floors to zero" do
      it "requires an exact match for short patterns" do
        expect(described_class.match?("bet", "bat", ratio: 0.2)).to be(false)
      end
    end

    context "empty text" do
      it "cannot match a non-empty pattern" do
        expect(described_class.match?("hello", "", ratio: 0.2)).to be(false)
      end
    end
  end
end
