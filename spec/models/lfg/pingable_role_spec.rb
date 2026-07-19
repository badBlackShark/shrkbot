# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lfg::PingableRole do
  subject(:pingable_role) { build(:lfg_pingable_role) }

  it "is valid from the factory" do
    expect(pingable_role).to be_valid
  end

  describe "role_id" do
    it "is invalid when nil" do
      pingable_role.role_id = nil
      expect(pingable_role).not_to be_valid
    end
  end

  describe "uniqueness" do
    let(:lfg_settings) { create(:lfg_settings) }
    let!(:existing) { create(:lfg_pingable_role, lfg_settings:, role_id: 777) }

    it "is invalid for the same role_id under the same settings" do
      duplicate = build(:lfg_pingable_role, lfg_settings:, role_id: 777)
      expect(duplicate).not_to be_valid
    end

    it "is valid for the same role_id under a different settings" do
      other_settings = create(:lfg_settings)
      duplicate = build(:lfg_pingable_role, lfg_settings: other_settings, role_id: 777)
      expect(duplicate).to be_valid
    end
  end

  describe "min_membership_days" do
    it "is valid when nil" do
      pingable_role.min_membership_days = nil
      expect(pingable_role).to be_valid
    end

    it "is valid at 0" do
      pingable_role.min_membership_days = 0
      expect(pingable_role).to be_valid
    end

    it "is valid at 3_650" do
      pingable_role.min_membership_days = 3_650
      expect(pingable_role).to be_valid
    end

    it "is invalid at -1" do
      pingable_role.min_membership_days = -1
      expect(pingable_role).not_to be_valid
    end

    it "is invalid at 3_651" do
      pingable_role.min_membership_days = 3_651
      expect(pingable_role).not_to be_valid
    end
  end

  describe "allowed_channel_ids" do
    it "is valid when nil" do
      pingable_role.allowed_channel_ids = nil
      expect(pingable_role).to be_valid
    end

    it "is invalid when empty" do
      pingable_role.allowed_channel_ids = []
      expect(pingable_role).not_to be_valid
      expect(pingable_role.errors[:allowed_channel_ids]).to be_present
    end

    it "is valid with an id" do
      pingable_role.allowed_channel_ids = [123]
      expect(pingable_role).to be_valid
    end
  end

  describe "required_role_ids" do
    it "is valid when nil" do
      pingable_role.required_role_ids = nil
      expect(pingable_role).to be_valid
    end

    it "is valid when empty" do
      pingable_role.required_role_ids = []
      expect(pingable_role).to be_valid
    end

    it "is invalid at 51 entries" do
      pingable_role.required_role_ids = Array.new(51) { |i| i + 1 }
      expect(pingable_role).not_to be_valid
      expect(pingable_role.errors[:required_role_ids]).to be_present
    end
  end

  describe "excluded_role_ids" do
    it "is valid when nil" do
      pingable_role.excluded_role_ids = nil
      expect(pingable_role).to be_valid
    end

    it "is valid when empty" do
      pingable_role.excluded_role_ids = []
      expect(pingable_role).to be_valid
    end

    it "is invalid at 51 entries" do
      pingable_role.excluded_role_ids = Array.new(51) { |i| i + 1 }
      expect(pingable_role).not_to be_valid
      expect(pingable_role.errors[:excluded_role_ids]).to be_present
    end
  end
end
