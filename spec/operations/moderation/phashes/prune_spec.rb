# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Moderation::Phashes::Prune do
  subject(:result) { described_class.call }

  let!(:stale_phash) { create(:phash, last_seen_at: 31.days.ago) }
  let!(:stale_confirmed_phash) { create(:phash, last_seen_at: 40.days.ago) }
  let!(:fresh_orphan) { create(:phash, last_seen_at: 1.day.ago) }
  let!(:fresh_confirmed_phash) { create(:phash, last_seen_at: 1.day.ago) }

  before do
    create(:phash_confirmation, phash: stale_confirmed_phash)
    create(:phash_confirmation, phash: fresh_confirmed_phash)
  end

  it "deletes phashes not matched in 30 days and their confirmations" do
    result
    expect(Moderation::Phash.exists?(stale_phash.id)).to be(false)
    expect(Moderation::Phash.exists?(stale_confirmed_phash.id)).to be(false)
    expect(Moderation::PhashConfirmation.where(phash_id: stale_confirmed_phash.id)).to be_empty
  end

  it "deletes fresh phashes that have no confirmations" do
    result
    expect(Moderation::Phash.exists?(fresh_orphan.id)).to be(false)
  end

  it "keeps fresh phashes that still have confirmations" do
    result
    expect(Moderation::Phash.exists?(fresh_confirmed_phash.id)).to be(true)
  end

  it "succeeds" do
    expect(result).to be_success
  end
end
