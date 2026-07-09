# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::SpamTracker do
  subject(:tracker) { described_class.new }

  let(:guild_id) { 1 }
  let(:author_id) { 42 }
  let(:fingerprint) { 999 }
  let(:window) { 60 }
  let(:threshold) { 3 }
  let(:similarity) { 1.0 }
  let(:base_time) { Time.now }

  def record(channel_id:, at: base_time, fp: fingerprint)
    tracker.record(
      guild_id:,
      author_id:,
      fingerprint: fp,
      message_id: rand(100_000),
      channel_id:,
      at:,
      window:,
      threshold:,
      similarity:
    )
  end

  it "returns nil when below threshold" do
    record(channel_id: 1)
    record(channel_id: 2)
    expect(record(channel_id: 2)).to be_nil
  end

  it "returns a non-followup hit with all entries when distinct channels reach threshold" do
    record(channel_id: 1)
    record(channel_id: 2)
    result = record(channel_id: 3)
    expect(result).not_to be_followup
    expect(result.entries.map(&:channel_id)).to contain_exactly(1, 2, 3)
  end

  it "does NOT reach threshold when same channel repeated" do
    record(channel_id: 1)
    record(channel_id: 1)
    expect(record(channel_id: 1)).to be_nil
  end

  it "sweeps entries older than window so they do not count" do
    record(channel_id: 1, at: base_time - 61)
    record(channel_id: 2, at: base_time - 61)
    record(channel_id: 3, at: base_time)
    expect(record(channel_id: 4, at: base_time)).to be_nil
  end

  it "counts distinct channel_ids regardless of thread/order" do
    record(channel_id: 10)
    record(channel_id: 20)
    expect(record(channel_id: 30)).to be_a(described_class::Hit)
  end

  context "with similarity < 1.0" do
    let(:similarity) { 0.85 }
    let(:text_a) { "the quick brown fox jumps over the lazy dog" }
    let(:text_b) { "the quick brown fox jumps over the lazy cat" }

    it "groups two near-duplicate fingerprints into one bucket" do
      fp_a = Moderation::SimHash.fingerprint(text_a)
      fp_b = Moderation::SimHash.fingerprint(text_b)

      tracker.record(
        guild_id:, author_id:, fingerprint: fp_a, message_id: 1,
        channel_id: 1, at: base_time, window:, threshold:, similarity:
      )
      tracker.record(
        guild_id:, author_id:, fingerprint: fp_b, message_id: 2,
        channel_id: 2, at: base_time, window:, threshold:, similarity:
      )
      result = tracker.record(
        guild_id:, author_id:, fingerprint: fp_a, message_id: 3,
        channel_id: 3, at: base_time, window:, threshold:, similarity:
      )
      expect(result).to be_a(described_class::Hit)
    end
  end

  it "recording a String fingerprint then an Integer fingerprint raises no error" do
    expect {
      record(channel_id: 1, fp: "blank")
      record(channel_id: 2, fp: 12_345)
    }.not_to raise_error
  end

  describe "followup sweeping after a trigger" do
    before do
      record(channel_id: 1)
      record(channel_id: 2)
      record(channel_id: 3)
    end

    it "returns a followup hit with only the new entry while the window is hot" do
      result = record(channel_id: 4, at: base_time + 5)
      expect(result).to be_followup
      expect(result.entries.map(&:channel_id)).to eq([4])
    end

    it "keeps the window rolling while followups keep coming" do
      record(channel_id: 4, at: base_time + 55)
      result = record(channel_id: 5, at: base_time + 110)
      expect(result).to be_followup
    end

    it "starts a fresh count once the window has passed quietly" do
      expect(record(channel_id: 4, at: base_time + 61)).to be_nil
    end

    it "requires the full threshold again after the trigger window expires" do
      record(channel_id: 4, at: base_time + 61)
      record(channel_id: 5, at: base_time + 62)
      expect(record(channel_id: 6, at: base_time + 63)).not_to be_followup
    end
  end

  describe ".instance" do
    it "memoizes a single shared instance" do
      expect(described_class.instance).to be(described_class.instance)
    end
  end
end
