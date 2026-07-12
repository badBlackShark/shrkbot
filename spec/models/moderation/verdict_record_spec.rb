# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::VerdictRecord do
  subject(:record) { build(:verdict_record) }

  it "uses the correct table name" do
    expect(described_class.table_name).to eq("moderation_verdicts")
  end

  it "persists via the factory" do
    expect { create(:verdict_record) }.to change(described_class, :count).by(1)
  end

  it "belongs to a server configuration" do
    expect(record.server_configuration).to be_a(ServerConfiguration)
  end

  it "requires a discord_user_id" do
    record.discord_user_id = nil
    expect(record).not_to be_valid
    expect(record.errors[:discord_user_id]).to be_present
  end

  it "requires an action" do
    record.action = nil
    expect(record).not_to be_valid
    expect(record.errors[:action]).to be_present
  end

  it "requires a punishment" do
    record.punishment = nil
    expect(record).not_to be_valid
    expect(record.errors[:punishment]).to be_present
  end

  it "rejects an action outside the allowed set" do
    record.action = "explode"
    expect(record).not_to be_valid
    expect(record.errors[:action]).to be_present
  end

  it "accepts each allowed action" do
    described_class.actions.keys.each do |action|
      record.action = action
      expect(record).to be_valid
    end
  end

  it "rejects a punishment outside the allowed set" do
    record.punishment = "exile"
    expect(record).not_to be_valid
    expect(record.errors[:punishment]).to be_present
  end

  it "accepts each allowed punishment" do
    described_class.punishments.keys.each do |punishment|
      record.punishment = punishment
      expect(record).to be_valid
    end
  end

  describe ".for_user" do
    subject(:results) { described_class.for_user(discord_user_id) }

    let(:discord_user_id) { 999_888_777 }
    let!(:matching) { create(:verdict_record, discord_user_id:) }
    let!(:other) { create(:verdict_record, discord_user_id: 111_222_333) }

    it "returns records for the given discord_user_id" do
      expect(results).to contain_exactly(matching)
    end
  end

  describe ".recent" do
    subject(:results) { described_class.recent }

    let!(:older) { create(:verdict_record, created_at: 2.days.ago) }
    let!(:newer) { create(:verdict_record, created_at: 1.day.ago) }

    it "orders by created_at descending" do
      expect(results.first).to eq(newer)
      expect(results.last).to eq(older)
    end
  end
end
