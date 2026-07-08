# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Moderation::ImageScanning::Configure do
  subject(:result) do
    described_class.call(
      server_configuration: config,
      sensitivity:,
      action:,
      punishment:,
      timeout_seconds:,
      custom_keywords:,
      custom_keyword_min_hits:,
      enabled:
    )
  end

  let(:config) { create(:server_configuration) }
  let!(:plugin) { create(:plugin, key: "image_scanning", name: "Scam Image Detection") }
  let!(:settings) { config.create_image_scanning_settings! }
  let(:sensitivity) { "standard" }
  let(:action) { "delete" }
  let(:punishment) { "none" }
  let(:timeout_seconds) { 3600 }
  let(:custom_keywords) { [] }
  let(:custom_keyword_min_hits) { 2 }
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
    let(:custom_keywords) { %w[free nitro click here] }
    let(:custom_keyword_min_hits) { 2 }

    before { setup_moderation_group_enabled }

    it "succeeds" do
      expect(result).to be_success
    end

    it "saves the settings including custom_keywords" do
      result
      reloaded = config.image_scanning_settings.reload
      expect(reloaded.sensitivity).to eq("standard")
      expect(reloaded.custom_keywords).to eq(%w[free nitro click here])
    end

    it "enables the image_scanning activation" do
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

    it "persists nothing for image_scanning" do
      result
      expect(config.plugin_activations.find_by(plugin:)).to be_nil
    end
  end

  context "when sensitivity is invalid with enabled 0" do
    let(:sensitivity) { "medium" }
    let(:enabled) { "0" }

    it "fails via settings validation" do
      expect(result).to be_failure
    end
  end

  context "when custom_keyword_min_hits exceeds keyword count" do
    let(:custom_keywords) { %w[scam] }
    let(:custom_keyword_min_hits) { 3 }
    let(:enabled) { "0" }

    it "fails via settings validation" do
      expect(result).to be_failure
    end
  end

  context "when saving settings without enabling" do
    let(:enabled) { "0" }
    let(:custom_keywords) { %w[scam free] }

    before { setup_moderation_group_enabled }

    it "succeeds" do
      expect(result).to be_success
    end

    it "saves the custom_keywords round-trip" do
      result
      expect(config.image_scanning_settings.reload.custom_keywords).to eq(%w[scam free])
    end

    it "does not enable the activation" do
      result
      expect(config.plugin_activations.find_by(plugin:)&.enabled).to be_falsey
    end
  end
end
