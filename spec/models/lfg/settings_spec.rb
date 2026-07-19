# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lfg::Settings do
  subject(:settings) { build(:lfg_settings) }

  it "is valid from the factory" do
    expect(settings).to be_valid
  end

  describe "cooldown_seconds" do
    it "is valid at 0" do
      settings.cooldown_seconds = 0
      expect(settings).to be_valid
    end

    it "is valid at 86_400" do
      settings.cooldown_seconds = 86_400
      expect(settings).to be_valid
    end

    it "is invalid at -1" do
      settings.cooldown_seconds = -1
      expect(settings).not_to be_valid
    end

    it "is invalid at 86_401" do
      settings.cooldown_seconds = 86_401
      expect(settings).not_to be_valid
    end
  end

  describe "post_lifetime_minutes" do
    it "is valid at 5" do
      settings.post_lifetime_minutes = 5
      expect(settings).to be_valid
    end

    it "is valid at 10_080" do
      settings.post_lifetime_minutes = 10_080
      expect(settings).to be_valid
    end

    it "is invalid at 4" do
      settings.post_lifetime_minutes = 4
      expect(settings).not_to be_valid
    end

    it "is invalid at 10_081" do
      settings.post_lifetime_minutes = 10_081
      expect(settings).not_to be_valid
    end
  end

  describe "default_min_membership_days" do
    it "is valid when nil" do
      settings.default_min_membership_days = nil
      expect(settings).to be_valid
    end

    it "is valid at 0" do
      settings.default_min_membership_days = 0
      expect(settings).to be_valid
    end

    it "is valid at 3_650" do
      settings.default_min_membership_days = 3_650
      expect(settings).to be_valid
    end

    it "is invalid at -1" do
      settings.default_min_membership_days = -1
      expect(settings).not_to be_valid
    end

    it "is invalid at 3_651" do
      settings.default_min_membership_days = 3_651
      expect(settings).not_to be_valid
    end
  end

  describe "default_required_role_ids" do
    it "is valid when empty" do
      settings.default_required_role_ids = []
      expect(settings).to be_valid
    end

    it "is valid with a few ids" do
      settings.default_required_role_ids = [1, 2, 3]
      expect(settings).to be_valid
    end

    it "is invalid at 51 entries" do
      settings.default_required_role_ids = Array.new(51) { |i| i + 1 }
      expect(settings).not_to be_valid
      expect(settings.errors[:default_required_role_ids]).to be_present
    end
  end

  describe "default_excluded_role_ids" do
    it "is valid when empty" do
      settings.default_excluded_role_ids = []
      expect(settings).to be_valid
    end

    it "is valid with a few ids" do
      settings.default_excluded_role_ids = [1, 2, 3]
      expect(settings).to be_valid
    end

    it "is invalid at 51 entries" do
      settings.default_excluded_role_ids = Array.new(51) { |i| i + 1 }
      expect(settings).not_to be_valid
      expect(settings.errors[:default_excluded_role_ids]).to be_present
    end
  end

  describe "allowed_channel_ids" do
    it "is valid when empty" do
      settings.allowed_channel_ids = []
      expect(settings).to be_valid
    end

    it "is valid with a few ids" do
      settings.allowed_channel_ids = [1, 2, 3]
      expect(settings).to be_valid
    end

    it "is invalid at 51 entries" do
      settings.allowed_channel_ids = Array.new(51) { |i| i + 1 }
      expect(settings).not_to be_valid
      expect(settings.errors[:allowed_channel_ids]).to be_present
    end
  end
end
