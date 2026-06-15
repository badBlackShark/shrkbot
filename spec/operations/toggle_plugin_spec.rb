require "rails_helper"

RSpec.describe TogglePlugin do
  let(:server) { ServerConfiguration.create!(discord_id: 1) }
  let(:logging) { Plugin.create!(key: "logging", name: "Logging") }
  let(:roles) { Plugin.create!(key: "roles", name: "Roles") }

  it "refuses to enable logging until a channel is configured" do
    result = described_class.call(server_configuration: server, plugin: logging, enabled: true)

    expect(result.failure?).to be(true)
    expect(result.errors.first).to match(/required settings/)
    expect(server.plugin_activations).to be_empty
  end

  it "enables logging once a channel is set" do
    server.create_logging_setting!(channel_id: 999)

    result = described_class.call(server_configuration: server, plugin: logging, enabled: true)

    expect(result.success?).to be(true)
    expect(result.value.enabled).to be(true)
  end

  it "enables a plugin without prerequisites (roles gate lands in Phase 4)" do
    result = described_class.call(server_configuration: server, plugin: roles, enabled: true)
    expect(result.success?).to be(true)
  end

  it "disables a plugin regardless of settings, reusing the activation row" do
    server.plugin_activations.create!(plugin: logging, enabled: true)

    result = described_class.call(server_configuration: server, plugin: logging, enabled: false)

    expect(result.success?).to be(true)
    expect(result.value.enabled).to be(false)
    expect(server.plugin_activations.where(plugin: logging).count).to eq(1)
  end
end
