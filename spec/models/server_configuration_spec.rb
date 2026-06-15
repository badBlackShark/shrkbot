require "rails_helper"

RSpec.describe ServerConfiguration do
  it "generates a prefixed-uuid primary key" do
    server = ServerConfiguration.create!(discord_id: 789)
    expect(server.id).to match(/\Asrv_\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
  end

  it "exposes only enabled plugins via #enabled_plugins" do
    server = ServerConfiguration.create!(discord_id: 123)
    logging = Plugin.create!(key: "logging", name: "Logging")
    roles = Plugin.create!(key: "roles", name: "Roles")
    server.plugin_activations.create!(plugin: logging, enabled: true)
    server.plugin_activations.create!(plugin: roles, enabled: false)

    expect(server.enabled_plugins).to eq([logging])
  end

  it "forbids duplicate activations of the same plugin" do
    server = ServerConfiguration.create!(discord_id: 456)
    plugin = Plugin.create!(key: "logging", name: "Logging")
    server.plugin_activations.create!(plugin: plugin)

    expect(server.plugin_activations.build(plugin: plugin)).not_to be_valid
  end
end
