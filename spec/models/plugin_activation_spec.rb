# frozen_string_literal: true

require "rails_helper"

RSpec.describe PluginActivation do
  subject(:activation) { build(:plugin_activation, server_configuration: server, plugin:, enabled:) }

  let(:server) { create(:server_configuration) }
  let(:plugin) { create(:plugin, key: "welcomes", name: "Welcomes") }

  context "enabling a channel-backed plugin without its channel" do
    let(:enabled) { true }

    it { is_expected.not_to be_valid }
  end

  context "enabling a channel-backed plugin once its channel is set" do
    let(:enabled) { true }

    before do
      server.create_welcome_settings!(channel_id: 5)
    end

    it { is_expected.to be_valid }
  end

  context "disabling, regardless of settings" do
    let(:enabled) { false }

    it { is_expected.to be_valid }
  end

  describe ".enabled_counts_for" do
    subject(:counts) { described_class.enabled_counts_for([server_a.discord_id, server_b.discord_id]) }

    let(:server_a) { create(:server_configuration) }
    let(:server_b) { create(:server_configuration) }
    let(:plugin_a) { create(:plugin) }
    let(:plugin_b) { create(:plugin) }

    before do
      create(:plugin_activation, server_configuration: server_a, plugin: plugin_a, enabled: true)
      create(:plugin_activation, server_configuration: server_a, plugin: plugin_b, enabled: false)
      create(:plugin_activation, server_configuration: server_b, plugin: plugin_a, enabled: true)
      create(:plugin_activation, server_configuration: server_b, plugin: plugin_b, enabled: true)
    end

    it "counts only enabled activations" do
      expect(counts[server_a.discord_id]).to eq(1)
    end

    it "groups counts by discord_id" do
      expect(counts[server_b.discord_id]).to eq(2)
    end

    it "omits servers with no enabled activations" do
      empty_server = create(:server_configuration)
      result = described_class.enabled_counts_for([empty_server.discord_id])
      expect(result).not_to have_key(empty_server.discord_id)
    end
  end
end
