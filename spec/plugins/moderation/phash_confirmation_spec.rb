# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::PhashConfirmation do
  subject(:confirmation) { build(:phash_confirmation) }

  it "uses the correct table name" do
    expect(described_class.table_name).to eq("phash_confirmations")
  end

  it "persists via the factory" do
    expect { create(:phash_confirmation) }.to change(described_class, :count).by(1)
  end

  it "belongs to a phash" do
    expect(confirmation.phash).to be_a(Moderation::Phash)
  end

  it "belongs to a server configuration" do
    expect(confirmation.server_configuration).to be_a(ServerConfiguration)
  end

  it "requires a verdict" do
    confirmation.verdict = nil
    expect(confirmation).not_to be_valid
    expect(confirmation.errors[:verdict]).to be_present
  end

  it "rejects a verdict outside the allowed set" do
    confirmation.verdict = "maybe"
    expect(confirmation).not_to be_valid
    expect(confirmation.errors[:verdict]).to be_present
  end

  it "accepts each allowed verdict" do
    described_class.verdicts.keys.each do |verdict|
      confirmation.verdict = verdict
      expect(confirmation).to be_valid
    end
  end

  context "when confirmed" do
    before do
      confirmation.verdict = "confirmed"
    end

    it { is_expected.to be_confirmed }
  end
end
