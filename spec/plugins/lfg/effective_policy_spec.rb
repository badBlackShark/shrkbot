# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lfg::EffectivePolicy do
  subject(:policy) { described_class.new(settings, pingable_role) }

  let(:settings) do
    build(
      :lfg_settings,
      default_min_membership_days: 7,
      default_required_role_ids: [1, 2],
      default_excluded_role_ids: [3, 4],
      allowed_channel_ids: [5, 6]
    )
  end
  let(:pingable_role) do
    build(
      :lfg_pingable_role,
      lfg_settings: settings,
      min_membership_days: role_min_membership_days,
      required_role_ids: role_required_role_ids,
      excluded_role_ids: role_excluded_role_ids,
      allowed_channel_ids: role_allowed_channel_ids
    )
  end
  let(:role_min_membership_days) { nil }
  let(:role_required_role_ids) { nil }
  let(:role_excluded_role_ids) { nil }
  let(:role_allowed_channel_ids) { nil }

  describe "#min_membership_days" do
    subject(:min_membership_days) { policy.min_membership_days }

    context "when the role override is nil" do
      it "inherits the settings default" do
        expect(min_membership_days).to eq(7)
      end
    end

    context "when the role override is present" do
      let(:role_min_membership_days) { 14 }

      it "uses the role override" do
        expect(min_membership_days).to eq(14)
      end
    end
  end

  describe "#feature_required_role_ids" do
    subject(:feature_required_role_ids) { policy.feature_required_role_ids }

    it "is always the settings default" do
      expect(feature_required_role_ids).to eq([1, 2])
    end
  end

  describe "#role_required_role_ids" do
    subject(:role_required_role_ids_result) { policy.role_required_role_ids }

    context "when the role has no required roles of its own" do
      let(:role_required_role_ids) { nil }

      it "returns an empty array" do
        expect(role_required_role_ids_result).to eq([])
      end
    end

    context "when the role has its own required roles" do
      let(:role_required_role_ids) { [10] }

      it "returns the role's own required roles" do
        expect(role_required_role_ids_result).to eq([10])
      end
    end
  end

  describe "#excluded_role_ids" do
    subject(:excluded_role_ids) { policy.excluded_role_ids }

    context "when the role has no excluded roles of its own" do
      let(:role_excluded_role_ids) { nil }

      it "is just the settings default" do
        expect(excluded_role_ids).to eq([3, 4])
      end
    end

    context "when the role has its own excluded roles" do
      let(:role_excluded_role_ids) { [10] }

      it "is the union of the default and the role's own" do
        expect(excluded_role_ids).to contain_exactly(3, 4, 10)
      end
    end

    context "when the role's excluded roles overlap with the default" do
      let(:role_excluded_role_ids) { [3, 10] }

      it "dedupes the union" do
        expect(excluded_role_ids).to contain_exactly(3, 4, 10)
      end
    end
  end

  describe "#allowed_channel_ids" do
    subject(:allowed_channel_ids) { policy.allowed_channel_ids }

    context "when the role override is nil" do
      it "inherits the settings default" do
        expect(allowed_channel_ids).to eq([5, 6])
      end
    end

    context "when the role override is an empty array" do
      let(:role_allowed_channel_ids) { [] }

      it "returns the empty array, not the default" do
        expect(allowed_channel_ids).to eq([])
      end
    end

    context "when the role override is a populated array" do
      let(:role_allowed_channel_ids) { [10] }

      it "returns the role override" do
        expect(allowed_channel_ids).to eq([10])
      end
    end
  end
end
