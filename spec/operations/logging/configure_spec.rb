# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Logging::Configure do
  subject(:result) do
    described_class.call(
      server_configuration: config,
      channel_id:,
      enabled_actions:,
      enabled:
    )
  end

  let(:config) { create(:server_configuration) }
  let!(:plugin) { create(:plugin, key: "logging", name: "Logging") }
  let!(:settings) { config.create_logging_setting! }
  let(:channel_id) { 200 }
  let(:enabled_actions) { {"roles.role_gained" => true, "roles.role_lost" => false} }
  let(:enabled) { "1" }

  context "with a channel, enabling the plugin" do
    it "saves the channel, event toggles, and enables the plugin" do
      expect(result).to be_success
      expect(config.logging_setting.reload.channel_id).to eq(200)
      expect(config.logging_setting.action_enabled?("roles.role_gained")).to be(true)
      expect(config.logging_setting.action_enabled?("roles.role_lost")).to be(false)
      expect(config.plugin_activations.find_by(plugin:).enabled).to be(true)
    end
  end

  context "when enabling without a channel" do
    let(:channel_id) { "" }

    it "fails with an error on the enabled field and persists nothing" do
      expect(result).to be_failure
      expect(result.value.errors[:enabled]).to be_present
      expect(config.plugin_activations.reload).to be_empty
    end
  end

  context "when saving event toggles without enabling" do
    let(:enabled) { "0" }
    let(:channel_id) { "" }

    it "stores the toggles and leaves the plugin disabled" do
      expect(result).to be_success
      expect(config.logging_setting.reload.action_enabled?("roles.role_gained")).to be(true)
      expect(config.plugin_activations.find_by(plugin:)&.enabled).to be_falsey
    end
  end

  context "when moderation is enabled and logging would become unavailable" do
    let!(:moderation_plugin) { create(:plugin, key: "moderation", name: "Server Shield") }

    before do
      config.logging_setting.update!(channel_id: 200)
      create(:plugin_activation, server_configuration: config, plugin:, enabled: true)
      create(:plugin_activation, server_configuration: config, plugin: moderation_plugin, enabled: true)
    end

    context "when disabling logging" do
      let(:enabled) { "0" }
      let(:channel_id) { 200 }

      it "fails with an error on enabled" do
        expect(result).to be_failure
        expect(result.value.errors[:enabled]).to be_present
      end

      it "leaves logging enabled" do
        result
        expect(config.plugin_activations.find_by(plugin:).enabled).to be(true)
      end
    end

    context "when clearing the logging channel while keeping enabled" do
      let(:enabled) { "1" }
      let(:channel_id) { "" }

      it "fails with an error on enabled" do
        expect(result).to be_failure
        expect(result.value.errors[:enabled]).to be_present
      end
    end
  end
end
