require "rails_helper"

RSpec.describe ServerConfiguration do
  it "generates a prefixed-uuid primary key" do
    server = create(:server_configuration, discord_id: 789)
    expect(server.id).to match(/\Asrv_\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
  end

  it "exposes only enabled plugins via #enabled_plugins" do
    server = create(:server_configuration, discord_id: 123)
    logging = create(:plugin, key: "logging", name: "Logging")
    roles = create(:plugin, key: "roles", name: "Roles")
    create(:plugin_activation, server_configuration: server, plugin: logging, enabled: true)
    create(:plugin_activation, server_configuration: server, plugin: roles, enabled: false)

    expect(server.enabled_plugins).to eq([logging])
  end

  it "forbids duplicate activations of the same plugin" do
    server = create(:server_configuration, discord_id: 456)
    plugin = create(:plugin, key: "logging", name: "Logging")
    create(:plugin_activation, server_configuration: server, plugin: plugin)

    expect(server.plugin_activations.build(plugin: plugin)).not_to be_valid
  end
end
