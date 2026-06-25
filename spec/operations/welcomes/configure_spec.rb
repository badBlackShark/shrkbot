# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Welcomes::Configure do
  subject(:result) do
    described_class.call(
      server_configuration: config,
      channel_id: channel_id,
      join_message: "hi {user}",
      leave_message: "bye",
      enabled: enabled
    )
  end

  let(:config) { create(:server_configuration) }
  let!(:plugin) { create(:plugin, key: "welcomes", name: "Welcomes") }
  let!(:settings) { config.create_welcome_settings! }
  let(:channel_id) { 111 }
  let(:enabled) { "1" }

  context "with a channel, enabling the plugin" do
    it "saves the settings and enables the plugin" do
      expect(result).to be_success
      expect(config.welcome_settings.reload.channel_id).to eq(111)
      expect(config.welcome_settings.join_message).to eq("hi {user}")
      expect(config.plugin_activations.find_by(plugin: plugin).enabled).to be(true)
    end
  end

  context "when enabling without a channel" do
    let(:channel_id) { "" }

    it "fails with an error on the enabled field and persists nothing" do
      expect(result).to be_failure
      expect(result.value.errors[:enabled]).to be_present
      expect(config.welcome_settings.reload.channel_id).to be_nil
      expect(config.plugin_activations.reload).to be_empty
    end
  end

  context "when saving messages without enabling" do
    let(:enabled) { "0" }
    let(:channel_id) { "" }

    it "saves the messages and leaves the plugin disabled" do
      expect(result).to be_success
      expect(config.welcome_settings.reload.join_message).to eq("hi {user}")
      expect(config.plugin_activations.find_by(plugin: plugin)&.enabled).to be_falsey
    end
  end
end
