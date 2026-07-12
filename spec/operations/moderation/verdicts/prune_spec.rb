# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Moderation::Verdicts::Prune do
  subject(:result) { described_class.call }

  let!(:old_record) { create(:verdict_record, created_at: 31.days.ago) }
  let!(:very_old_record) { create(:verdict_record, created_at: 60.days.ago) }
  let!(:fresh_record) { create(:verdict_record, created_at: 1.day.ago) }
  let!(:boundary_record) { create(:verdict_record, created_at: 29.days.ago) }

  it "deletes records older than 30 days" do
    result
    expect(Moderation::VerdictRecord.exists?(old_record.id)).to be(false)
    expect(Moderation::VerdictRecord.exists?(very_old_record.id)).to be(false)
  end

  it "keeps records newer than 30 days" do
    result
    expect(Moderation::VerdictRecord.exists?(fresh_record.id)).to be(true)
    expect(Moderation::VerdictRecord.exists?(boundary_record.id)).to be(true)
  end

  it "succeeds" do
    expect(result).to be_success
  end
end
