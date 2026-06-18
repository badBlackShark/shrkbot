require "rails_helper"

RSpec.describe Ops::ServerConfiguration::TogglePlugin do
  subject(:result) { described_class.call(server_configuration: server, plugin:, enabled:) }

  let(:server) { create(:server_configuration, discord_id: 1) }
  let(:logging) { create(:plugin, key: "logging", name: "Logging") }
  let(:roles) { create(:plugin, key: "roles", name: "Roles") }
  let(:welcomes) { create(:plugin, key: "welcomes", name: "Welcomes") }

  context "enabling logging without a channel" do
    let(:plugin) { logging }
    let(:enabled) { true }

    it "is refused until the channel is configured" do
      expect(result.failure?).to be(true)
      expect(result.errors.first).to match(/required settings/)
      expect(server.plugin_activations).to be_empty
    end
  end

  context "enabling logging once a channel is set" do
    let(:plugin) { logging }
    let(:enabled) { true }

    before { server.create_logging_setting!(channel_id: 999) }

    it "succeeds" do
      expect(result.success?).to be(true)
      expect(result.value.enabled).to be(true)
    end
  end

  context "enabling roles without a channel" do
    let(:plugin) { roles }
    let(:enabled) { true }

    it "is refused until the channel is configured" do
      expect(result.failure?).to be(true)
      expect(result.errors.first).to match(/required settings/)
    end
  end

  context "enabling roles once a channel is set" do
    let(:plugin) { roles }
    let(:enabled) { true }

    before { server.create_role_setting!(channel_id: 777) }

    it "succeeds" do
      expect(result.success?).to be(true)
    end
  end

  context "enabling welcomes without a channel" do
    let(:plugin) { welcomes }
    let(:enabled) { true }

    it "is refused until the channel is configured" do
      expect(result.failure?).to be(true)
      expect(result.errors.first).to match(/required settings/)
    end
  end

  context "enabling welcomes once a channel is set" do
    let(:plugin) { welcomes }
    let(:enabled) { true }

    before { server.create_welcome_settings!(channel_id: 42) }

    it "succeeds" do
      expect(result.success?).to be(true)
    end
  end

  context "disabling a plugin" do
    let(:plugin) { logging }
    let(:enabled) { false }

    before do
      server.create_logging_setting!(channel_id: 999)
      create(:plugin_activation, server_configuration: server, plugin: logging, enabled: true)
    end

    it "succeeds regardless of settings, reusing the activation row" do
      expect(result.success?).to be(true)
      expect(result.value.enabled).to be(false)
      expect(server.plugin_activations.where(plugin: logging).count).to eq(1)
    end
  end
end
