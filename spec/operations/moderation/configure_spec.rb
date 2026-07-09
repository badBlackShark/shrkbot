# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Moderation::Configure do
  subject(:result) do
    described_class.call(
      server_configuration: config,
      staff_role_id:,
      enabled:
    )
  end

  let(:config) { create(:server_configuration) }
  let!(:plugin) { create(:plugin, key: "moderation", name: "Server Shield") }
  let!(:settings) { config.create_moderation_settings! }
  let(:staff_role_id) { 111_222_333 }
  let(:enabled) { "1" }

  context "when enabling without logging ready (no logging plugin enabled)" do
    it "fails with an error on the enabled field" do
      expect(result).to be_failure
      expect(result.value.errors[:enabled]).to be_present
    end

    it "persists no activation" do
      result
      expect(config.plugin_activations.reload).to be_empty
    end
  end

  context "when enabling with logging plugin enabled but no channel set" do
    let!(:logging_plugin) { create(:plugin, key: "logging", name: "Logging") }

    before do
      config.create_logging_setting!(channel_id: nil)
      create(:plugin_activation, server_configuration: config, plugin: logging_plugin, enabled: false).update_column(:enabled, true)
    end

    it "fails with an error on the enabled field" do
      expect(result).to be_failure
      expect(result.value.errors[:enabled]).to be_present
    end
  end

  context "when enabling with logging plugin enabled but no logging setting record" do
    let!(:logging_plugin) { create(:plugin, key: "logging", name: "Logging") }

    before do
      create(:plugin_activation, server_configuration: config, plugin: logging_plugin, enabled: false).update_column(:enabled, true)
    end

    it "fails with an error on the enabled field" do
      expect(result).to be_failure
      expect(result.value.errors[:enabled]).to be_present
    end
  end

  context "when enabling with logging ready" do
    let!(:logging_plugin) { create(:plugin, key: "logging", name: "Logging") }

    before do
      config.create_logging_setting!(channel_id: 999)
      create(:plugin_activation, server_configuration: config, plugin: logging_plugin, enabled: true)
    end

    it "succeeds" do
      expect(result).to be_success
    end

    it "saves the staff_role_id" do
      result
      expect(config.moderation_settings.reload.staff_role_id).to eq(111_222_333)
    end

    it "enables the moderation activation" do
      result
      expect(config.plugin_activations.find_by(plugin:).enabled).to be(true)
    end
  end

  context "when saving staff_role_id without enabling (enabled 0)" do
    let(:enabled) { "0" }

    it "succeeds" do
      expect(result).to be_success
    end

    it "saves the staff_role_id" do
      result
      expect(config.moderation_settings.reload.staff_role_id).to eq(111_222_333)
    end

    it "does not enable the activation" do
      result
      expect(config.plugin_activations.find_by(plugin:)&.enabled).to be_falsey
    end
  end

  context "when clearing staff_role_id while a sub-plugin is enabled" do
    let(:staff_role_id) { nil }
    let(:enabled) { "0" }
    let!(:spam_plugin) { create(:plugin, key: "spam_protection", name: "Cross-Channel Spam Guard") }

    before do
      create(:plugin_activation, server_configuration: config, plugin: spam_plugin, enabled: false).update_column(:enabled, true)
    end

    it "fails with an error on staff_role_id" do
      expect(result).to be_failure
      expect(result.value.errors[:staff_role_id]).to be_present
    end

    it "does not save the cleared staff_role_id" do
      settings.update!(staff_role_id: 111_222_333)
      result
      expect(config.moderation_settings.reload.staff_role_id).to eq(111_222_333)
    end
  end

  context "when clearing staff_role_id with no sub-plugin enabled" do
    let(:staff_role_id) { nil }
    let(:enabled) { "0" }

    it "succeeds" do
      expect(result).to be_success
    end

    it "clears the staff_role_id" do
      settings.update!(staff_role_id: 111_222_333)
      result
      expect(config.moderation_settings.reload.staff_role_id).to be_nil
    end
  end

  context "when setting a staff_role_id while a sub-plugin is enabled" do
    let(:enabled) { "0" }
    let!(:spam_plugin) { create(:plugin, key: "spam_protection", name: "Cross-Channel Spam Guard") }

    before do
      create(:plugin_activation, server_configuration: config, plugin: spam_plugin, enabled: false).update_column(:enabled, true)
    end

    it "succeeds" do
      expect(result).to be_success
    end

    it "saves the staff_role_id" do
      result
      expect(config.moderation_settings.reload.staff_role_id).to eq(111_222_333)
    end
  end
end
