# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::ServerConfiguration::Plugins::Toggle do
  subject(:result) { described_class.call(server_configuration: server, plugin:, enabled:) }

  let(:server) { create(:server_configuration, discord_id: 1) }
  let(:logging) { create(:plugin, key: "logging", name: "Logging") }
  let(:roles) { create(:plugin, key: "roles", name: "Roles") }
  let(:welcomes) { create(:plugin, key: "welcomes", name: "Welcomes") }
  let(:spam_protection) { create(:plugin, key: "spam_protection", name: "Cross-Channel Spam Guard") }

  def activate(plugin)
    create(:plugin_activation, server_configuration: server, plugin:, enabled: false).tap do |activation|
      activation.update_column(:enabled, true)
    end
  end

  before do
    allow(Bot::ConfigBus).to receive(:sync_commands)
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

    it "returns an unsaved, disabled activation" do
      expect(result.value.enabled?).to be(false)
      expect(result.value.persisted?).to be(false)
    end
  end

  context "enabling logging with a channel assigned in memory but not saved" do
    let(:plugin) { logging }
    let(:enabled) { true }

    before do
      server.create_logging_settings!
      server.logging_settings.channel_id = 999
    end

    it "succeeds on the submitted value" do
      expect(result.success?).to be(true)
      expect(server.plugin_activations.find_by(plugin:).reload.enabled).to be(true)
    end
  end

  context "enabling Steam, which belongs to a group with no switch" do
    let(:plugin) { create(:plugin, key: "steam", name: "Steam") }
    let(:enabled) { true }

    it "succeeds" do
      expect(result.success?).to be(true)
    end
  end

  context "enabling logging without a channel while its activation is stored as disabled" do
    let(:plugin) { logging }
    let(:enabled) { true }
    let!(:activation) { create(:plugin_activation, server_configuration: server, plugin: logging, enabled: false) }

    it "returns the activation with the refused change reverted" do
      expect(result.value).to eq(activation)
      expect(result.value.enabled?).to be(false)
      expect(result.value.changed?).to be(false)
    end
  end

  context "enabling logging once a channel is set" do
    let(:plugin) { logging }
    let(:enabled) { true }

    before do
      server.create_logging_settings!(channel_id: 999)
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
      server.create_logging_settings!(channel_id: 999)
      create(:plugin_activation, server_configuration: server, plugin: logging, enabled: true)
    end

    it "succeeds regardless of settings, reusing the activation row" do
      expect(result.success?).to be(true)
      expect(result.value.enabled).to be(false)
      expect(server.plugin_activations.where(plugin: logging).count).to eq(1)
    end
  end

  context "enabling a bespoke plugin without a grant" do
    let(:plugin) { create(:plugin, key: "twilight_struggle", name: "Twilight Struggle") }
    let(:enabled) { true }

    it "is refused with the generic settings message" do
      expect(result.errors).to eq(["Twilight Struggle can't be enabled until its required settings are configured."])
    end
  end

  context "enabling a protection while Logging is off" do
    let(:plugin) { spam_protection }
    let(:enabled) { true }

    before do
      logging
      server.create_logging_settings!(channel_id: 999)
      server.create_moderation_settings!(staff_role_id: 5)
    end

    it "names every requirement" do
      expect(result.errors).to eq(["Cross-Channel Spam Guard needs Logging enabled, and a staff role set on the Server Shield overview."])
    end
  end

  context "enabling a protection while Logging is on without a channel" do
    let(:plugin) { spam_protection }
    let(:enabled) { true }

    before do
      server.create_logging_settings!
      server.create_moderation_settings!(staff_role_id: 5)
      activate(logging)
    end

    it "is refused" do
      expect(result.errors).to eq(["Cross-Channel Spam Guard needs Logging enabled, and a staff role set on the Server Shield overview."])
    end
  end

  context "enabling a protection without a staff role" do
    let(:plugin) { spam_protection }
    let(:enabled) { true }

    before do
      server.create_logging_settings!(channel_id: 999)
      server.create_moderation_settings!
      activate(logging)
    end

    it "is refused" do
      expect(result.errors).to eq(["Cross-Channel Spam Guard needs Logging enabled, and a staff role set on the Server Shield overview."])
    end
  end

  context "while a protection is on" do
    let(:plugin) { logging }
    let(:enabled) { false }

    before do
      server.create_logging_settings!(channel_id: 999)
      server.create_moderation_settings!(staff_role_id: 5)
      activate(logging)
      activate(spam_protection)
    end

    it "refuses to turn Logging off and leaves it on" do
      expect(result.errors).to eq(["Cross-Channel Spam Guard is on and depends on these settings. Turn Cross-Channel Spam Guard off first."])
      expect(server.plugin_activations.find_by(plugin: logging).reload.enabled).to be(true)
    end

    context "when the log channel is cleared in memory and Logging is saved as enabled" do
      let(:enabled) { true }

      before { server.logging_settings.channel_id = nil }

      it "refuses" do
        expect(result.errors).to eq(["Logging can't be enabled until its required settings are configured."])
      end
    end
  end

  context "when a plugin is saved as enabled again" do
    let(:enabled) { true }

    before do
      allow(Bot::ConfigBus).to receive(:post_roles)
    end

    context "with Logging" do
      let(:plugin) { logging }

      before do
        server.create_logging_settings!(channel_id: 999)
        activate(logging)
      end

      it "publishes no command sync" do
        result
        expect(Bot::ConfigBus).not_to have_received(:sync_commands)
      end
    end

    context "with Roles" do
      let(:plugin) { roles }

      before do
        create(:role_set, role_setting: create(:role_setting, server_configuration: server))
        activate(roles)
      end

      it "posts no menus" do
        result
        expect(Bot::ConfigBus).not_to have_received(:post_roles)
      end
    end
  end

  context "when the caller's transaction rolls back" do
    subject(:result) do
      ActiveRecord::Base.transaction do
        described_class.call(server_configuration: server, plugin:, enabled:)
        raise ActiveRecord::Rollback
      end
    end

    let(:plugin) { logging }
    let(:enabled) { true }

    before { server.create_logging_settings!(channel_id: 999) }

    it "publishes no command sync" do
      result
      expect(Bot::ConfigBus).not_to have_received(:sync_commands)
    end
  end

  context "sync_commands is published when enabled changes" do
    before do
      allow(Bot::ConfigBus).to receive(:post_roles)
      allow(Bot::ConfigBus).to receive(:remove_roles_menu)
    end

    context "when enabling logging" do
      let(:plugin) { logging }
      let(:enabled) { true }

      before { server.create_logging_settings!(channel_id: 999) }

      it "publishes sync_commands" do
        result
        expect(Bot::ConfigBus).to have_received(:sync_commands).with(server)
      end
    end

    context "when disabling logging" do
      let(:plugin) { logging }
      let(:enabled) { false }

      before do
        server.create_logging_settings!(channel_id: 999)
        create(:plugin_activation, server_configuration: server, plugin: logging, enabled: true)
      end

      it "publishes sync_commands" do
        result
        expect(Bot::ConfigBus).to have_received(:sync_commands).with(server)
      end
    end
  end

  context "toggling roles publishes menu sync" do
    let(:plugin) { roles }

    before do
      allow(Bot::ConfigBus).to receive(:post_roles)
      allow(Bot::ConfigBus).to receive(:remove_roles_menu)
      allow(Bot::ConfigBus).to receive(:delete_roles_message)
    end

    context "when enabling with a role_set" do
      let(:enabled) { true }
      let!(:role_setting) { create(:role_setting, server_configuration: server) }
      let!(:role_set) { create(:role_set, role_setting:) }

      it "publishes post_roles for the set" do
        result
        expect(Bot::ConfigBus).to have_received(:post_roles).with(
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
        expect(Bot::ConfigBus).to have_received(:remove_roles_menu).with(
          have_attributes(id: role_set.id)
        )
      end
    end
  end

  context "toggling a non-roles plugin" do
    let(:plugin) { logging }
    let(:enabled) { true }

    before do
      allow(Bot::ConfigBus).to receive(:post_roles)
      allow(Bot::ConfigBus).to receive(:remove_roles_menu)
      server.create_logging_settings!(channel_id: 999)
    end

    it "publishes neither post_roles nor remove_roles_menu" do
      result
      expect(Bot::ConfigBus).not_to have_received(:post_roles)
      expect(Bot::ConfigBus).not_to have_received(:remove_roles_menu)
    end
  end

  context "a refused roles enable (no role_setting)" do
    let(:plugin) { roles }
    let(:enabled) { true }

    before do
      allow(Bot::ConfigBus).to receive(:post_roles)
      allow(Bot::ConfigBus).to receive(:remove_roles_menu)
    end

    it "publishes nothing when the operation is refused" do
      result
      expect(Bot::ConfigBus).not_to have_received(:sync_commands)
      expect(Bot::ConfigBus).not_to have_received(:post_roles)
      expect(Bot::ConfigBus).not_to have_received(:remove_roles_menu)
    end
  end

  context "feeds follow times" do
    let(:plugin) { steam }
    let(:enabled) { true }
    let(:steam) { create(:plugin, key: "steam", name: "Steam") }
    let(:subscription) { create(:feed_subscription, server_configuration: server) }
    let!(:subscribed_event) { create(:feed_subscribed_event, subscription:, subscribed_since: 1.day.ago) }

    context "when enabling Steam" do
      it "resets the follow time" do
        expect { result }.to change { subscribed_event.reload.subscribed_since }
      end
    end

    context "when disabling Steam" do
      let(:enabled) { false }

      before do
        create(:plugin_activation, server_configuration: server, plugin: steam, enabled: true)
      end

      it "leaves the follow time alone" do
        expect { result }.not_to change { subscribed_event.reload.subscribed_since }
      end
    end

    context "when Steam is already enabled and saved as enabled again" do
      before do
        create(:plugin_activation, server_configuration: server, plugin: steam, enabled: true)
      end

      it "leaves the follow time alone" do
        expect { result }.not_to change { subscribed_event.reload.subscribed_since }
      end
    end
  end
end
