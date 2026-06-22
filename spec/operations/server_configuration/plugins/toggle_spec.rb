require "rails_helper"

RSpec.describe Ops::ServerConfiguration::Plugins::Toggle do
  subject(:result) { described_class.call(server_configuration: server, plugin:, enabled:) }

  let(:server) { create(:server_configuration, discord_id: 1) }
  let(:logging) { create(:plugin, key: "logging", name: "Logging") }
  let(:roles) { create(:plugin, key: "roles", name: "Roles") }
  let(:welcomes) { create(:plugin, key: "welcomes", name: "Welcomes") }

  context "with a raw checkbox value (form param, not yet cast)" do
    let(:plugin) { roles }

    before { server.create_role_setting!(channel_id: 777) }

    context "when checked" do
      let(:enabled) { "1" }

      it "enables the plugin" do
        expect(result.value.enabled?).to be(true)
      end
    end

    context "when unchecked" do
      let(:enabled) { "0" }

      it "leaves the plugin disabled" do
        expect(result.value.enabled?).to be(false)
      end
    end
  end

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

    before do
      server.create_logging_setting!(channel_id: 999)
    end

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

    before do
      server.create_role_setting!(channel_id: 777)
    end

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

    before do
      server.create_welcome_settings!(channel_id: 42)
    end

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
