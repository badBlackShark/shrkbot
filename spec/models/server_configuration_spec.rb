# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServerConfiguration do
  describe "primary key" do
    subject(:id) { server.id }

    let(:server) { create(:server_configuration, discord_id: 789) }

    it "generates a prefixed-uuid" do
      expect(id).to match(/\Asrv_\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
    end
  end

  describe "enabled plugins" do
    subject(:enabled_plugins) { server.plugins.enabled }

    let(:server) { create(:server_configuration, discord_id: 123) }
    let(:logging) { create(:plugin, key: "logging", name: "Logging") }
    let(:roles) { create(:plugin, key: "roles", name: "Roles") }

    before do
      server.create_logging_setting!(channel_id: 999)
      create(:plugin_activation, server_configuration: server, plugin: logging, enabled: true)
      create(:plugin_activation, server_configuration: server, plugin: roles, enabled: false)
    end

    it "exposes only enabled plugins" do
      expect(enabled_plugins).to eq([logging])
    end
  end

  describe "plugin_activations uniqueness" do
    subject(:activation) { server.plugin_activations.build(plugin:) }

    let(:server) { create(:server_configuration, discord_id: 456) }
    let(:plugin) { create(:plugin, key: "logging", name: "Logging") }

    before do
      create(:plugin_activation, server_configuration: server, plugin:)
    end

    it "forbids duplicate activations of the same plugin" do
      expect(activation).not_to be_valid
    end
  end

  describe ".configured_ids_among" do
    subject(:ids) { described_class.configured_ids_among(discord_ids) }

    let!(:config_a) { create(:server_configuration, discord_id: 111_111_111) }
    let!(:config_b) { create(:server_configuration, discord_id: 222_222_222) }

    context "with a mix of present and absent discord_ids" do
      let(:discord_ids) { [111_111_111, 999_999_999] }

      it "returns only the discord_ids present in the database" do
        expect(ids).to contain_exactly(111_111_111)
      end
    end
  end

  describe "#icon_url" do
    subject(:icon_url) { server.icon_url }

    let(:server) { create(:server_configuration, discord_id: 900_000_001, icon_hash:) }

    context "when icon_hash is present" do
      let(:icon_hash) { "abc123" }

      it "builds the Discord CDN URL" do
        expect(icon_url).to eq("https://cdn.discordapp.com/icons/900000001/abc123.png?size=64")
      end
    end

    context "when icon_hash is nil" do
      let(:icon_hash) { nil }

      it { is_expected.to be_nil }
    end
  end
end
