# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Moderation::Phashes::MarkSeen do
  subject(:result) { described_class.call(phash_hex:) }

  let(:phash_hex) { "00000000000000ef" }

  context "when the phash is stale" do
    let!(:phash) { create(:phash, phash: phash_hex, last_seen_at: 2.hours.ago) }

    it "touches last_seen_at" do
      expect { result }.to change { phash.reload.last_seen_at }
      expect(result).to be_success
    end
  end

  context "when the phash was seen within the last hour" do
    let!(:phash) { create(:phash, phash: phash_hex, last_seen_at: 5.minutes.ago) }

    it "does not touch last_seen_at" do
      expect { result }.not_to change { phash.reload.last_seen_at }
      expect(result).to be_success
    end
  end

  context "when no phash matches the hex" do
    it "succeeds without touching anything" do
      expect { result }.not_to change(Moderation::Phash, :count)
      expect(result).to be_success
    end
  end
end
