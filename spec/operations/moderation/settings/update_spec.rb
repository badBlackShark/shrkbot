# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Moderation::Settings::Update do
  subject(:result) do
    described_class.call(
      server_configuration: config,
      staff_role_id:,
      ping_staff:,
      new_account_age_days:
    )
  end

  let(:config) { create(:server_configuration) }
  let!(:settings) { config.create_moderation_settings! }
  let(:staff_role_id) { 111_222_333 }
  let(:ping_staff) { "1" }
  let(:new_account_age_days) { 30 }

  def enable_protection(plugin)
    logging_plugin = create(:plugin, key: "logging", name: "Logging")
    config.create_logging_settings!(channel_id: 999)
    [logging_plugin, plugin].each do |enabled_plugin|
      create(:plugin_activation, server_configuration: config, plugin: enabled_plugin, enabled: false).update_column(:enabled, true)
    end
  end

  context "when saving the staff role" do
    it "succeeds" do
      expect(result).to be_success
    end

    it "saves the staff_role_id" do
      result
      expect(config.moderation_settings.reload.staff_role_id).to eq(111_222_333)
    end
  end

  context "when clearing staff_role_id while a sub-plugin is enabled" do
    let(:staff_role_id) { nil }
    let!(:spam_plugin) { create(:plugin, key: "spam_protection", name: "Cross-Channel Spam Guard") }

    before do
      settings.update!(staff_role_id: 111_222_333)
      enable_protection(spam_plugin)
    end

    it "fails naming the sub-plugin" do
      expect(result).to be_failure
      expect(result.errors).to eq(["Cross-Channel Spam Guard is on and depends on these settings. Turn Cross-Channel Spam Guard off first."])
    end

    it "does not save the cleared staff_role_id" do
      result
      expect(config.moderation_settings.reload.staff_role_id).to eq(111_222_333)
    end
  end

  context "when clearing staff_role_id with no sub-plugin enabled" do
    let(:staff_role_id) { nil }

    it "succeeds" do
      expect(result).to be_success
    end

    it "clears the staff_role_id" do
      settings.update!(staff_role_id: 111_222_333)
      result
      expect(config.moderation_settings.reload.staff_role_id).to be_nil
    end
  end

  context "when a protection is missing something this save does not touch" do
    let!(:spam_plugin) { create(:plugin, key: "spam_protection", name: "Cross-Channel Spam Guard") }

    before do
      settings.update!(staff_role_id: 111_222_333)
      enable_protection(spam_plugin)
      config.logging_settings.update!(channel_id: nil)
    end

    it "refuses the save" do
      expect(result.errors).to eq(["Cross-Channel Spam Guard is on and depends on these settings. Turn Cross-Channel Spam Guard off first."])
    end
  end

  context "when setting a staff_role_id while a sub-plugin is enabled" do
    let!(:spam_plugin) { create(:plugin, key: "spam_protection", name: "Cross-Channel Spam Guard") }

    before do
      enable_protection(spam_plugin)
    end

    it "succeeds" do
      expect(result).to be_success
    end

    it "saves the staff_role_id" do
      result
      expect(config.moderation_settings.reload.staff_role_id).to eq(111_222_333)
    end
  end

  context "when saving ping_staff: '0'" do
    let(:ping_staff) { "0" }

    it "succeeds" do
      expect(result).to be_success
    end

    it "persists ping_staff as false" do
      result
      expect(config.moderation_settings.reload.ping_staff).to be(false)
    end
  end

  context "when saving ping_staff: '1'" do
    let(:ping_staff) { "1" }

    before { settings.update!(ping_staff: false) }

    it "persists ping_staff as true" do
      result
      expect(config.moderation_settings.reload.ping_staff).to be(true)
    end
  end

  context "when setting new_account_age_days to a custom value" do
    let(:new_account_age_days) { 90 }

    it "persists the new value" do
      result
      expect(config.moderation_settings.reload.new_account_age_days).to eq(90)
    end
  end

  context "when new_account_age_days is blank" do
    let(:new_account_age_days) { nil }

    before { settings.update!(new_account_age_days: 45) }

    it "preserves the existing value" do
      result
      expect(config.moderation_settings.reload.new_account_age_days).to eq(45)
    end
  end

  context "when new_account_age_days is out of range" do
    let(:new_account_age_days) { 500 }

    it "fails with an error on the field rather than raising" do
      expect(result).to be_failure
      expect(result.errors).to eq(["New account age days must be less than or equal to 365"])
    end

    it "persists nothing" do
      result
      expect(config.moderation_settings.reload.new_account_age_days).to eq(30)
    end
  end
end
