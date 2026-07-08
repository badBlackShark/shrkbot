# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::SimHash do
  describe ".fingerprint" do
    it "is deterministic — same text produces same integer on repeated calls" do
      expect(described_class.fingerprint("hello world foo bar")).to eq(
        described_class.fingerprint("hello world foo bar")
      )
    end

    it "returns an Integer" do
      expect(described_class.fingerprint("some text")).to be_a(Integer)
    end

    it "returns 0 for empty string" do
      expect(described_class.fingerprint("")).to eq(0)
    end
  end

  describe ".hamming_distance" do
    it "returns 0 for identical strings" do
      fp = described_class.fingerprint("the quick brown fox")
      expect(described_class.hamming_distance(fp, fp)).to eq(0)
    end

    it "returns a small distance for a near-identical string (one word changed)" do
      fp_a = described_class.fingerprint("the quick brown fox jumps over the lazy dog")
      fp_b = described_class.fingerprint("the quick brown fox jumps over the lazy cat")
      expect(described_class.hamming_distance(fp_a, fp_b)).to be <= 10
    end

    it "returns a large distance for unrelated text" do
      fp_a = described_class.fingerprint("completely different content here one two three")
      fp_b = described_class.fingerprint("zephyr quartz jolly vexing backlash")
      expect(described_class.hamming_distance(fp_a, fp_b)).to be > 10
    end
  end

  describe ".similar?" do
    let(:base_text) { "the quick brown fox jumps over the lazy dog" }
    let(:near_text) { "the quick brown fox jumps over the lazy cat" }

    it "returns true at similarity 1.0 only when hamming distance is 0" do
      fp = described_class.fingerprint(base_text)
      expect(described_class.similar?(fp, fp, similarity: 1.0)).to be true
    end

    it "returns false at similarity 1.0 for unrelated text" do
      fp_a = described_class.fingerprint("completely different content here one two three")
      fp_b = described_class.fingerprint("zephyr quartz jolly vexing backlash")
      expect(described_class.similar?(fp_a, fp_b, similarity: 1.0)).to be false
    end

    it "returns true at similarity 0.85 for a near-identical pair" do
      fp_a = described_class.fingerprint(base_text)
      fp_b = described_class.fingerprint(near_text)
      expect(described_class.similar?(fp_a, fp_b, similarity: 0.85)).to be true
    end
  end
end
