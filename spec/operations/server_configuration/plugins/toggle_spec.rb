# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::ServerConfiguration::Plugins::Toggle do
  subject(:result) { described_class.call(server_configuration: server, plugin:, enabled:) }

  let(:server) { create(:server_configuration, discord_id: 1) }
  let(:logging) { create(:plugin, key: "logging", name: "Logging") }
  let(:roles) { create(:plugin, key: "roles", name: "Roles") }
  let(:welcomes) { create(:plugin, key: "welcomes", name: "Welcomes") }

  before do
    allow(ConfigBus).to receive(:sync_commands)
  end

  context "with a raw checkbox value (form param, not yet cast)" do
    let(:plugin) { roles }

    before do
      server.create_role_setting!(channel_id: 777)
    end

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

  context "sync_commands is published on every successful toggle" do
    before do
      allow(ConfigBus).to receive(:post_roles)
      allow(ConfigBus).to receive(:remove_roles_menu)
    end

    context "when enabling logging" do
      let(:plugin) { logging }
      let(:enabled) { true }

      before { server.create_logging_setting!(channel_id: 999) }

      it "publishes sync_commands" do
        result
        expect(ConfigBus).to have_received(:sync_commands).with(server)
      end
    end

    context "when disabling logging" do
      let(:plugin) { logging }
      let(:enabled) { false }

      before do
        server.create_logging_setting!(channel_id: 999)
        create(:plugin_activation, server_configuration: server, plugin: logging, enabled: true)
      end

      it "publishes sync_commands" do
        result
        expect(ConfigBus).to have_received(:sync_commands).with(server)
      end
    end
  end

  context "toggling roles publishes menu sync" do
    let(:plugin) { roles }

    before do
      allow(ConfigBus).to receive(:post_roles)
      allow(ConfigBus).to receive(:remove_roles_menu)
      allow(ConfigBus).to receive(:delete_roles_message)
    end

    context "when enabling with a role_set" do
      let(:enabled) { true }
      let!(:role_setting) { create(:role_setting, server_configuration: server) }
      let!(:role_set) { create(:role_set, role_setting:) }

      it "publishes post_roles for the set" do
        result
        expect(ConfigBus).to have_received(:post_roles).with(
          have_attributes(id: role_set.id)
        )
      end
    end

    context "when disabling with a role_set that has a message" do
      let(:enabled) { false }
      let!(:role_setting) { create(:role_setting, server_configuration: server) }
      let!(:role_set) { create(:role_set, role_setting:, message_id: 111) }

      before do
        create(:plugin_activation, server_configuration: server, plugin: roles, enabled: true)
      end

      it "publishes remove_roles_menu for the set" do
        result
        expect(ConfigBus).to have_received(:remove_roles_menu).with(
          have_attributes(id: role_set.id)
        )
      end
    end
  end

  context "toggling a non-roles plugin" do
    let(:plugin) { logging }
    let(:enabled) { true }

    before do
      allow(ConfigBus).to receive(:post_roles)
      allow(ConfigBus).to receive(:remove_roles_menu)
      server.create_logging_setting!(channel_id: 999)
    end

    it "publishes neither post_roles nor remove_roles_menu" do
      result
      expect(ConfigBus).not_to have_received(:post_roles)
      expect(ConfigBus).not_to have_received(:remove_roles_menu)
    end
  end

  context "a refused roles enable (no role_setting)" do
    let(:plugin) { roles }
    let(:enabled) { true }

    before do
      allow(ConfigBus).to receive(:post_roles)
      allow(ConfigBus).to receive(:remove_roles_menu)
    end

    it "publishes nothing when the operation is refused" do
      result
      expect(ConfigBus).not_to have_received(:sync_commands)
      expect(ConfigBus).not_to have_received(:post_roles)
      expect(ConfigBus).not_to have_received(:remove_roles_menu)
    end
  end
end
