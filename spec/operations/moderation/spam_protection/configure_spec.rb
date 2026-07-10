# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Moderation::SpamProtection::Configure do
  subject(:result) do
    described_class.call(
      server_configuration: config,
      channel_threshold:,
      window_seconds:,
      similarity:,
      match_symbol_only_messages:,
      action:,
      punishment:,
      timeout_seconds:,
      enabled:
    )
  end

  let(:config) { create(:server_configuration) }
  let!(:plugin) { create(:plugin, key: "spam_protection", name: "Cross-Channel Spam Guard") }
  let!(:settings) { config.create_spam_protection_settings! }
  let(:channel_threshold) { 4 }
  let(:window_seconds) { 15 }
  let(:similarity) { 1.0 }
  let(:match_symbol_only_messages) { false }
  let(:action) { "purge" }
  let(:punishment) { "none" }
  let(:timeout_seconds) { 3600 }
  let(:enabled) { "1" }

  def setup_moderation_group_enabled
    logging_plugin = create(:plugin, key: "logging", name: "Logging")
    moderation_plugin = create(:plugin, key: "moderation", name: "Server Shield")
    config.create_logging_setting!(channel_id: 999)
    config.create_moderation_settings!.tap { |s| s.update!(staff_role_id: 777_888_999) }
    create(:plugin_activation, server_configuration: config, plugin: logging_plugin, enabled: true)
    create(:plugin_activation, server_configuration: config, plugin: moderation_plugin, enabled: true)
  end

  context "when moderation group is enabled and staff_role_id is set (happy path)" do
    before { setup_moderation_group_enabled }

    it "succeeds" do
      expect(result).to be_success
    end

    it "saves the settings" do
      result
      expect(config.spam_protection_settings.reload.channel_threshold).to eq(4)
    end

    it "enables the spam_protection activation" do
      result
      expect(config.plugin_activations.find_by(plugin:).enabled).to be(true)
    end
  end

  context "when enabling while staff_role_id is blank" do
    before do
      logging_plugin = create(:plugin, key: "logging", name: "Logging")
      moderation_plugin = create(:plugin, key: "moderation", name: "Server Shield")
      config.create_logging_setting!(channel_id: 999)
      config.create_moderation_settings!
      create(:plugin_activation, server_configuration: config, plugin: logging_plugin, enabled: true)
      create(:plugin_activation, server_configuration: config, plugin: moderation_plugin, enabled: true)
    end

    it "fails" do
      expect(result).to be_failure
    end

    it "reports an error on enabled" do
      expect(result.value.errors[:enabled]).to be_present
    end

    it "persists nothing for spam_protection" do
      result
      expect(config.plugin_activations.find_by(plugin:)).to be_nil
    end
  end

  context "when channel_threshold is invalid (1) with enabled 0" do
    let(:channel_threshold) { 1 }
    let(:enabled) { "0" }

    it "fails via settings validation" do
      expect(result).to be_failure
    end
  end

  context "when saving settings without enabling" do
    let(:enabled) { "0" }

    before { setup_moderation_group_enabled }

    it "succeeds" do
      expect(result).to be_success
    end

    it "does not enable the activation" do
      result
      expect(config.plugin_activations.find_by(plugin:)&.enabled).to be_falsey
    end
  end

  context "when enabling with no moderation settings record at all" do
    it "fails the staff-role guard" do
      expect(result).to be_failure
      expect(result.value.errors[:enabled]).to be_present
    end
  end

  context "with an unknown action" do
    let(:action) { "delete" }
    let(:enabled) { "0" }

    it "fails" do
      expect(result).to be_failure
    end

    it "reports an error mentioning action" do
      expect(result.errors.join(" ")).to match(/action/i)
    end
  end
end
