# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::TwilightStruggle::Configure do
  subject(:result) { described_class.call(server_configuration:, enabled:) }

  let(:server_configuration) { create(:server_configuration) }
  let!(:plugin) { create(:plugin, key: "twilight_struggle", name: "Twilight Struggle") }
  let!(:grant) { create(:bespoke_plugin_grant, server_configuration:, plugin_key: "twilight_struggle") }
  let(:enabled) { "1" }

  before do
    allow(Bot::ConfigBus).to receive(:sync_commands)
  end

  it "enables the plugin for the server" do
    result
    expect(server_configuration.reload.enabled_plugin_keys).to include(:twilight_struggle)
  end

  it "resyncs the guild commands" do
    result
    expect(Bot::ConfigBus).to have_received(:sync_commands).with(server_configuration)
  end

  it "returns the plugin activation" do
    expect(result.value).to be_a(PluginActivation)
  end

  context "when disabling" do
    let!(:activation) { create(:plugin_activation, server_configuration:, plugin:, enabled: true) }
    let(:enabled) { "0" }

    it "disables the plugin" do
      result
      expect(server_configuration.reload.enabled_plugin_keys).not_to include(:twilight_struggle)
    end
  end

  context "when the server has no grant" do
    let!(:grant) { nil }

    it "fails" do
      expect(result).to be_failure
    end

    it "does not enable the plugin" do
      result
      expect(server_configuration.reload.enabled_plugin_keys).not_to include(:twilight_struggle)
    end
  end
end
