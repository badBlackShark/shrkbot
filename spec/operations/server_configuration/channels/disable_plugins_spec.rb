# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::ServerConfiguration::Channels::DisablePlugins do
  subject(:result) { described_class.call(server_configuration: server, channel_id:, bot:) }

  let(:server) { create(:server_configuration, discord_id: 1) }
  let(:bot) { double("bot") }
  let(:channel_id) { 555 }
  let(:welcomes) { create(:plugin, key: "welcomes", name: "Welcomes") }

  before do
    allow(OwnerNotifier).to receive(:notify)
  end

  context "when a plugin's configured channel was deleted" do
    before do
      server.create_welcome_settings!(channel_id: 555)
      create(:plugin_activation, server_configuration: server, plugin: welcomes, enabled: true)
    end

    it "disables the plugin, clears the dead channel, and notifies the owner" do
      result

      expect(server.plugin_activations.find_by(plugin: welcomes).enabled).to be(false)
      expect(server.welcome_settings.reload.channel_id).to be_nil
      expect(OwnerNotifier).to have_received(:notify).with(hash_including(bot:))
    end

    it "creates a channel_deleted notification for the server" do
      expect { result }.to change(Notification, :count).by(1)

      notification = server.notifications.last
      expect(notification.kind).to eq("channel_deleted")
      expect(notification.data["plugin_key"]).to eq("welcomes")
    end

    context "when the server_channels row exists for the deleted channel" do
      before do
        create(:server_channel, server_configuration: server, discord_id: 555, name: "general")
      end

      it "stores the channel_name in the notification data" do
        result

        expect(server.notifications.last.data["channel_name"]).to eq("general")
      end
    end

    context "when the server_channels row is absent (offline delete)" do
      it "stores nil channel_name in the notification data" do
        result

        expect(server.notifications.last.data["channel_name"]).to be_nil
      end
    end
  end

  context "when the deleted channel isn't used by any plugin" do
    before do
      server.create_welcome_settings!(channel_id: 999)
    end

    it "changes nothing and doesn't notify" do
      result

      expect(server.welcome_settings.reload.channel_id).to eq(999)
      expect(OwnerNotifier).not_to have_received(:notify)
    end

    it "creates no notifications" do
      expect { result }.not_to change(Notification, :count)
    end
  end
end
