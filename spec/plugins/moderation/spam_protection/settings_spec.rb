# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::SpamProtection::Settings do
  subject(:settings) { build(:spam_protection_settings) }

  it "is valid from the factory" do
    expect(settings).to be_valid
  end

  describe "channel_threshold" do
    it "is invalid at 1" do
      settings.channel_threshold = 1
      expect(settings).not_to be_valid
    end

    it "is invalid at 501" do
      settings.channel_threshold = 501
      expect(settings).not_to be_valid
    end

    it "is valid at 2" do
      settings.channel_threshold = 2
      expect(settings).to be_valid
    end

    it "is valid at 500" do
      settings.channel_threshold = 500
      expect(settings).to be_valid
    end
  end

  describe "window_seconds" do
    it "is invalid at 0" do
      settings.window_seconds = 0
      expect(settings).not_to be_valid
    end

    it "is invalid at 61" do
      settings.window_seconds = 61
      expect(settings).not_to be_valid
    end

    it "is valid at 60" do
      settings.window_seconds = 60
      expect(settings).to be_valid
    end
  end

  describe "similarity" do
    it "is invalid at 0.74" do
      settings.similarity = 0.74
      expect(settings).not_to be_valid
    end

    it "is invalid at 1.01" do
      settings.similarity = 1.01
      expect(settings).not_to be_valid
    end

    it "is valid at 0.75" do
      settings.similarity = 0.75
      expect(settings).to be_valid
    end

    it "is valid at 1.0" do
      settings.similarity = 1.0
      expect(settings).to be_valid
    end
  end

  describe "action" do
    it "is invalid for an unrecognised value" do
      settings.action = "delete"
      expect(settings).not_to be_valid
    end

    it "is valid for purge" do
      settings.action = "purge"
      expect(settings).to be_valid
    end

    it "is valid for notify_only" do
      settings.action = "notify_only"
      expect(settings).to be_valid
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

  describe ".active_for" do
    subject(:active_setting) { described_class.active_for(discord_id) }

    let(:server) { create(:server_configuration, discord_id: 123) }
    let!(:spam_settings) { create(:spam_protection_settings, server_configuration: server) }
    let(:discord_id) { 123 }

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

    context "when only spam_protection is enabled (moderation not enabled)" do
      let!(:moderation_plugin) { create(:plugin, key: "moderation", name: "Server Shield") }
      let!(:spam_plugin) { create(:plugin, key: "spam_protection", name: "Cross-Channel Spam Guard") }

      before do
        create(:plugin_activation, server_configuration: server, plugin: moderation_plugin, enabled: false)
        create(:plugin_activation, server_configuration: server, plugin: spam_plugin, enabled: false).update_column(:enabled, true)
      end

      it "returns nil" do
        expect(active_setting).to be_nil
      end
    end

    context "when both moderation and spam_protection are enabled" do
      let!(:logging_plugin) { create(:plugin, key: "logging", name: "Logging") }
      let!(:moderation_plugin) { create(:plugin, key: "moderation", name: "Server Shield") }
      let!(:spam_plugin) { create(:plugin, key: "spam_protection", name: "Cross-Channel Spam Guard") }

      before do
        server.create_logging_setting!(channel_id: 999)
        create(:plugin_activation, server_configuration: server, plugin: logging_plugin, enabled: true)
        create(:plugin_activation, server_configuration: server, plugin: moderation_plugin, enabled: true)
        create(:plugin_activation, server_configuration: server, plugin: spam_plugin, enabled: true)
      end

      it "returns the spam protection settings" do
        expect(active_setting).to eq(spam_settings)
      end
    end
  end
end
