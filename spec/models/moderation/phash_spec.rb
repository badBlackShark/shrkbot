# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::Phash do
  subject(:phash) { build(:phash) }

  it "uses the correct table name" do
    expect(described_class.table_name).to eq("phashes")
  end

  it "persists via the factory" do
    expect { create(:phash) }.to change(described_class, :count).by(1)
  end

  it "requires a phash" do
    phash.phash = nil
    expect(phash).not_to be_valid
    expect(phash.errors[:phash]).to be_present
  end

  it "requires last_seen_at" do
    phash.last_seen_at = nil
    expect(phash).not_to be_valid
    expect(phash.errors[:last_seen_at]).to be_present
  end

  it "requires a unique phash" do
    existing = create(:phash)
    duplicate = build(:phash, phash: existing.phash)
    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:phash]).to be_present
  end

  it "deletes its confirmations when destroyed" do
    persisted = create(:phash)
    create(:phash_confirmation, phash: persisted)
    expect { persisted.destroy }.to change(Moderation::PhashConfirmation, :count).by(-1)
  end
end
