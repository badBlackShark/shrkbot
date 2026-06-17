require "rails_helper"

RSpec.describe ServerConfiguration do
  describe "primary key" do
    subject(:id) { server.id }

    let(:server) { create(:server_configuration, discord_id: 789) }

    it "generates a prefixed-uuid" do
      expect(id).to match(/\Asrv_\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
    end
  end

  describe "#enabled_plugins" do
    subject(:enabled_plugins) { server.enabled_plugins }

    let(:server) { create(:server_configuration, discord_id: 123) }
    let(:logging) { create(:plugin, key: "logging", name: "Logging") }
    let(:roles) { create(:plugin, key: "roles", name: "Roles") }

    before do
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

    before { create(:plugin_activation, server_configuration: server, plugin:) }

    it "forbids duplicate activations of the same plugin" do
      expect(activation).not_to be_valid
    end
  end
end
