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
  let(:feature_required_role_ids) { [] }
  let(:role_required_role_ids) { [] }
  let(:excluded_role_ids) { [] }
  let(:allowed_channel_ids) { [] }
  let(:effective) do
    double(
      "effective",
      min_membership_days:,
      feature_required_role_ids:,
      role_required_role_ids:,
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

    it "denies with channel_not_allowed and the allowed channels as detail" do
      expect(result.denied?).to be(true)
      expect(result.reason).to eq(:channel_not_allowed)
      expect(result.detail).to eq([999])
    end

    it "wins even when a later check would also fail" do
      allow(effective).to receive(:feature_required_role_ids).and_return([12345])

      expect(result.reason).to eq(:channel_not_allowed)
    end
  end

  context "when the feature-level required role is missing" do
    let(:feature_required_role_ids) { [999] }

    it "denies with missing_required_role and the feature set as detail" do
      expect(result.denied?).to be(true)
      expect(result.reason).to eq(:missing_required_role)
      expect(result.detail).to eq([999])
    end

    it "fails on the feature gate even when the member holds a role-required id" do
      allow(effective).to receive(:role_required_role_ids).and_return([7])

      expect(result.reason).to eq(:missing_required_role)
    end
  end

  context "when the feature-level required role is present" do
    let(:feature_required_role_ids) { [7] }

    it "passes that gate" do
      expect(result.ok?).to be(true)
    end
  end

  context "when the per-role required role is missing" do
    let(:feature_required_role_ids) { [7] }
    let(:role_required_role_ids) { [999] }

    it "denies with missing_game_role and the role set as detail" do
      expect(result.denied?).to be(true)
      expect(result.reason).to eq(:missing_game_role)
      expect(result.detail).to eq([999])
    end
  end

  context "when both the feature and per-role required roles are satisfied" do
    let(:feature_required_role_ids) { [7] }
    let(:role_required_role_ids) { [7] }

    it "passes both gates" do
      expect(result.ok?).to be(true)
    end
  end

  context "when an excluded role is present" do
    let(:excluded_role_ids) { [7] }

    it "denies with has_excluded_role and the blocking ids as detail" do
      expect(result.denied?).to be(true)
      expect(result.reason).to eq(:has_excluded_role)
      expect(result.detail).to eq([7])
    end
  end

  context "when the member holds only some of the excluded roles" do
    let(:member_role_ids) { [7, 8] }
    let(:excluded_role_ids) { [8, 9] }

    it "denies with only the intersecting ids as detail" do
      expect(result.denied?).to be(true)
      expect(result.reason).to eq(:has_excluded_role)
      expect(result.detail).to eq([8])
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
