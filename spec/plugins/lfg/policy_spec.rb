# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lfg::Policy do
  subject(:result) do
    described_class.new(
      effective:,
      channel_id:,
      member_role_ids:,
      member_joined_at:,
      cooldown_remaining:,
      now:
    ).result
  end

  let(:now) { Time.current }
  let(:channel_id) { 20 }
  let(:member_role_ids) { [7] }
  let(:member_joined_at) { now - 100.days }
  let(:cooldown_remaining) { 0 }
  let(:min_membership_days) { nil }
  let(:required_role_ids) { [] }
  let(:excluded_role_ids) { [] }
  let(:allowed_channel_ids) { [] }
  let(:effective) do
    double(
      "effective",
      min_membership_days:,
      required_role_ids:,
      excluded_role_ids:,
      allowed_channel_ids:
    )
  end

  context "when everything passes" do
    it "is ok" do
      expect(result.ok?).to be(true)
      expect(result.denied?).to be(false)
    end
  end

  context "when the channel isn't allowed" do
    let(:allowed_channel_ids) { [999] }

    it "denies with channel_not_allowed" do
      expect(result.denied?).to be(true)
      expect(result.reason).to eq(:channel_not_allowed)
    end

    it "wins even when a later check would also fail" do
      allow(effective).to receive(:required_role_ids).and_return([12345])

      expect(result.reason).to eq(:channel_not_allowed)
    end
  end

  context "when a required role is missing" do
    let(:required_role_ids) { [999] }

    it "denies with missing_required_role" do
      expect(result.denied?).to be(true)
      expect(result.reason).to eq(:missing_required_role)
    end
  end

  context "when a required role is present" do
    let(:required_role_ids) { [7] }

    it "passes that check" do
      expect(result.ok?).to be(true)
    end
  end

  context "when an excluded role is present" do
    let(:excluded_role_ids) { [7] }

    it "denies with has_excluded_role" do
      expect(result.denied?).to be(true)
      expect(result.reason).to eq(:has_excluded_role)
    end
  end

  context "when membership is too new" do
    let(:min_membership_days) { 30 }
    let(:member_joined_at) { now - 1.day }

    it "denies with too_new and the day count as detail" do
      expect(result.denied?).to be(true)
      expect(result.reason).to eq(:too_new)
      expect(result.detail).to eq(30)
    end
  end

  context "when membership is old enough" do
    let(:min_membership_days) { 30 }
    let(:member_joined_at) { now - 31.days }

    it "passes" do
      expect(result.ok?).to be(true)
    end
  end

  context "when min_membership_days is nil" do
    let(:min_membership_days) { nil }
    let(:member_joined_at) { now }

    it "passes regardless of join date" do
      expect(result.ok?).to be(true)
    end
  end

  context "when min_membership_days is set but joined_at is nil" do
    let(:min_membership_days) { 30 }
    let(:member_joined_at) { nil }

    it "denies with too_new" do
      expect(result.denied?).to be(true)
      expect(result.reason).to eq(:too_new)
    end
  end

  context "when on cooldown" do
    let(:cooldown_remaining) { 42 }

    it "denies with cooldown and remaining seconds as detail" do
      expect(result.denied?).to be(true)
      expect(result.reason).to eq(:cooldown)
      expect(result.detail).to eq(42)
    end
  end

  context "when cooldown remaining is zero" do
    let(:cooldown_remaining) { 0 }

    it "passes" do
      expect(result.ok?).to be(true)
    end
  end
end
