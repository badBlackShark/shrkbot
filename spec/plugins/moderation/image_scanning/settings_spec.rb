# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::ImageScanning::Settings do
  subject(:settings) { build(:image_scanning_settings) }

  it "is valid from the factory" do
    expect(settings).to be_valid
  end

  describe "sensitivity" do
    it "is invalid for an unrecognised value" do
      settings.sensitivity = "medium"
      expect(settings).not_to be_valid
    end

    %w[relaxed standard strict].each do |value|
      it "is valid for #{value}" do
        settings.sensitivity = value
        expect(settings).to be_valid
      end
    end

    it "returns true for strict? when set to strict" do
      settings.sensitivity = "strict"
      expect(settings.strict?).to be(true)
    end
  end

  describe "action" do
    it "is invalid for an unrecognised value" do
      settings.action = "purge"
      expect(settings).not_to be_valid
    end

    %w[none delete].each do |value|
      it "is valid for #{value}" do
        settings.action = value
        expect(settings).to be_valid
      end
    end
  end

  describe "punishment (via Punishable)" do
    it "is invalid for an unrecognised value" do
      settings.punishment = "mute"
      expect(settings).not_to be_valid
    end

    %w[none timeout kick ban].each do |punishment|
      it "is valid for #{punishment}" do
        settings.punishment = punishment
        expect(settings).to be_valid
      end
    end
  end

  describe "timeout_seconds" do
    it "is invalid at 59" do
      settings.timeout_seconds = 59
      expect(settings).not_to be_valid
    end

    it "is invalid at 2_419_201" do
      settings.timeout_seconds = 2_419_201
      expect(settings).not_to be_valid
    end
  end

  describe "custom_keywords" do
    it "is valid when empty" do
      settings.custom_keywords = []
      expect(settings).to be_valid
    end

    it "is valid with entries" do
      settings.custom_keywords = %w[scam giveaway]
      expect(settings).to be_valid
    end

    it "is invalid with a blank entry" do
      settings.custom_keywords = ["scam", "  ", "giveaway"]
      expect(settings).not_to be_valid
      expect(settings.errors[:custom_keywords]).to be_present
    end

    it "is invalid with a whitespace-only entry" do
      settings.custom_keywords = [""]
      expect(settings).not_to be_valid
    end

    it "is invalid with 201 entries" do
      settings.custom_keywords = Array.new(201) { |i| "k#{i}" }
      expect(settings).not_to be_valid
      expect(settings.errors[:custom_keywords]).to be_present
    end
  end

  describe "custom_keyword_min_hits" do
    it "is invalid at 0" do
      settings.custom_keywords = %w[a b]
      settings.custom_keyword_min_hits = 0
      expect(settings).not_to be_valid
    end

    it "is invalid when greater than keyword count" do
      settings.custom_keywords = %w[a b]
      settings.custom_keyword_min_hits = 3
      expect(settings).not_to be_valid
      expect(settings.errors[:custom_keyword_min_hits]).to be_present
    end

    it "is valid when equal to keyword count" do
      settings.custom_keywords = %w[a b]
      settings.custom_keyword_min_hits = 2
      expect(settings).to be_valid
    end

    it "is valid at any value >= 1 when keywords are empty" do
      settings.custom_keywords = []
      settings.custom_keyword_min_hits = 5
      expect(settings).to be_valid
    end
  end

  describe ".active_for" do
    subject(:active_setting) { described_class.active_for(discord_id) }

    let(:server) { create(:server_configuration, discord_id: 456) }
    let!(:scan_settings) { create(:image_scanning_settings, server_configuration: server) }
    let(:discord_id) { 456 }

    context "when no server configuration exists" do
      let(:discord_id) { 999 }

      it "returns nil" do
        expect(active_setting).to be_nil
      end
    end

    context "when only moderation is enabled" do
      let!(:logging_plugin) { create(:plugin, key: "logging", name: "Logging") }
      let!(:moderation_plugin) { create(:plugin, key: "moderation", name: "Server Shield") }

      before do
        server.create_logging_setting!(channel_id: 999)
        create(:plugin_activation, server_configuration: server, plugin: logging_plugin, enabled: true)
        create(:plugin_activation, server_configuration: server, plugin: moderation_plugin, enabled: true)
      end

      it "returns nil" do
        expect(active_setting).to be_nil
      end
    end

    context "when only image_scanning is enabled (moderation not enabled)" do
      let!(:moderation_plugin) { create(:plugin, key: "moderation", name: "Server Shield") }
      let!(:scan_plugin) { create(:plugin, key: "image_scanning", name: "Scam Image Detection") }

      before do
        create(:plugin_activation, server_configuration: server, plugin: moderation_plugin, enabled: false)
        create(:plugin_activation, server_configuration: server, plugin: scan_plugin, enabled: false).update_column(:enabled, true)
      end

      it "returns nil" do
        expect(active_setting).to be_nil
      end
    end

    context "when both moderation and image_scanning are enabled" do
      let!(:logging_plugin) { create(:plugin, key: "logging", name: "Logging") }
      let!(:moderation_plugin) { create(:plugin, key: "moderation", name: "Server Shield") }
      let!(:scan_plugin) { create(:plugin, key: "image_scanning", name: "Scam Image Detection") }

      before do
        server.create_logging_setting!(channel_id: 999)
        create(:plugin_activation, server_configuration: server, plugin: logging_plugin, enabled: true)
        create(:plugin_activation, server_configuration: server, plugin: moderation_plugin, enabled: true)
        create(:plugin_activation, server_configuration: server, plugin: scan_plugin, enabled: false).update_column(:enabled, true)
      end

      it "returns the image scanning settings" do
        expect(active_setting).to eq(scan_settings)
      end
    end
  end
end
