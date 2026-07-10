# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::TimeoutLogLedger do
  subject(:first_sighting) do
    ledger.first_sighting?(
      guild_id:,
      user_id:,
      expires_at:
    )
  end

  let(:ledger) { described_class.new }
  let(:guild_id) { 111 }
  let(:user_id) { 222 }
  let(:expires_at) { Time.current + 300 }

  it "returns true on the first call for a (guild, user, expiry)" do
    expect(first_sighting).to be(true)
  end

  context "when the same timeout was already recorded" do
    before do
      ledger.first_sighting?(guild_id:, user_id:, expires_at:)
    end

    it "returns false" do
      expect(first_sighting).to be(false)
    end
  end

  context "when the same guild and user were recorded with an earlier expiry" do
    before do
      ledger.first_sighting?(guild_id:, user_id:, expires_at: expires_at - 60)
    end

    it "returns true" do
      expect(first_sighting).to be(true)
    end
  end

  context "when a different user in the same guild has the same expiry" do
    before do
      ledger.first_sighting?(guild_id:, user_id: 333, expires_at:)
    end

    it "returns true" do
      expect(first_sighting).to be(true)
    end
  end

  context "when the previously recorded entry has expired" do
    let(:expires_at) { Time.current - 60 }

    before do
      ledger.first_sighting?(guild_id:, user_id:, expires_at:)
    end

    it "returns true because the swept entry counts as a first sighting again" do
      expect(first_sighting).to be(true)
    end
  end

  describe ".instance" do
    it "memoizes a single shared instance" do
      expect(described_class.instance).to be(described_class.instance)
    end
  end
end
