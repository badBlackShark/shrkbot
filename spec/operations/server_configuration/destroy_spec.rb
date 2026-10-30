# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::ServerConfiguration::Destroy do
  subject(:result) { described_class.call(server_configuration: config) }

  let!(:config) { create(:server_configuration) }

  it "destroys the server configuration" do
    result

    expect(ServerConfiguration.find_by(id: config.id)).to be_nil
  end

  it "returns success" do
    expect(result).to be_success
  end

  context "when the server configuration is a preview" do
    let!(:config) { create(:server_configuration, :preview) }

    it "does not destroy the server configuration" do
      result

      expect(ServerConfiguration.find_by(id: config.id)).to be_present
    end

    it "returns failure" do
      expect(result).to be_failure
    end
  end

  context "cascade to associated rows" do
    let!(:plugin) { create(:plugin, key: "test", name: "Test") }
    let!(:plugin_activation) { create(:plugin_activation, server_configuration: config, plugin:) }
    let!(:welcome_settings) { create(:welcome_settings, server_configuration: config) }
    let!(:server_channel) { create(:server_channel, server_configuration: config) }
    let!(:channel_overwrite) { create(:channel_overwrite, server_channel:) }
    let!(:server_role) { create(:server_role, server_configuration: config) }
    let!(:notification) { create(:notification, server_configuration: config) }
    let!(:role_setting) { create(:role_setting, server_configuration: config) }
    let!(:role_set) { create(:role_set, role_setting:) }
    let!(:assignable_role) { create(:assignable_role, role_set:) }
    let!(:lfg_settings) { create(:lfg_settings, server_configuration: config) }
    let!(:lfg_pingable_role) { create(:lfg_pingable_role, lfg_settings:) }
    let!(:lfg_message) { create(:lfg_message, server_configuration: config) }

    it "removes all associated rows" do
      result

      expect(PluginActivation.find_by(id: plugin_activation.id)).to be_nil
      expect(Welcomes::Settings.find_by(id: welcome_settings.id)).to be_nil
      expect(ServerChannel.find_by(id: server_channel.id)).to be_nil
      expect(ChannelOverwrite.find_by(id: channel_overwrite.id)).to be_nil
      expect(ServerRole.find_by(id: server_role.id)).to be_nil
      expect(Notification.find_by(id: notification.id)).to be_nil
      expect(Roles::Settings.find_by(id: role_setting.id)).to be_nil
      expect(Roles::Set.find_by(id: role_set.id)).to be_nil
      expect(Roles::AssignableRole.find_by(id: assignable_role.id)).to be_nil
      expect(Lfg::Settings.find_by(id: lfg_settings.id)).to be_nil
      expect(Lfg::PingableRole.find_by(id: lfg_pingable_role.id)).to be_nil
      expect(Lfg::Message.find_by(id: lfg_message.id)).to be_nil
    end
  end

  context "feed subscription handling" do
    let!(:subscription) { create(:feed_subscription, server_configuration: config) }
    let!(:subscribed_event) { create(:feed_subscribed_event, subscription:) }
    let!(:other_subscription) { create(:feed_subscription, watch: subscription.watch) }
    let!(:other_subscribed_event) { create(:feed_subscribed_event, subscription: other_subscription) }
    let!(:post) { create(:feed_post, subscription:) }
    let!(:steam_settings) { create(:feed_steam_settings, subscription:) }
    let!(:other_steam_settings) { create(:feed_steam_settings, subscription: other_subscription) }

    it "removes the server's subscriptions, their subscribed events and their posts" do
      result

      expect(Feeds::Subscription.find_by(id: subscription.id)).to be_nil
      expect(Feeds::SubscribedEvent.find_by(id: subscribed_event.id)).to be_nil
      expect(Feeds::Post.find_by(id: post.id)).to be_nil
      expect(Feeds::Steam::Settings.find_by(id: steam_settings.id)).to be_nil
    end

    it "leaves other servers' subscriptions and the shared watch untouched" do
      result

      expect(Feeds::Subscription.find_by(id: other_subscription.id)).to be_present
      expect(Feeds::SubscribedEvent.find_by(id: other_subscribed_event.id)).to be_present
      expect(Feeds::Steam::Settings.find_by(id: other_steam_settings.id)).to be_present
      expect(Integrations::Watch.find_by(id: subscription.watch_id)).to be_present
    end
  end

  context "twilight struggle destination handling" do
    let!(:tournament) { create(:twilight_struggle_tournament) }
    let!(:destination) do
      create(:twilight_struggle_destination, tournament:, server_configuration: config, discord_channel_id: 123456789012345678)
    end
    let!(:game) { create(:twilight_struggle_game, tournament:) }
    let!(:posted_message) { create(:twilight_struggle_posted_message, game:, server_configuration: config) }
    let!(:other_config) { create(:server_configuration) }
    let!(:other_destination) do
      create(:twilight_struggle_destination, tournament:, server_configuration: other_config, discord_channel_id: 876543210987654321)
    end
    let!(:other_posted_message) { create(:twilight_struggle_posted_message, game:, server_configuration: other_config) }

    it "destroys the server's destinations" do
      result

      expect(TwilightStruggle::Destination.find_by(id: destination.id)).to be_nil
    end

    it "destroys the server's posted-message rows" do
      result

      expect(TwilightStruggle::PostedMessage.find_by(id: posted_message.id)).to be_nil
    end

    it "leaves the tournament and game rows in place" do
      expect { result }.not_to change(TwilightStruggle::Tournament, :count)
      expect { result }.not_to change(TwilightStruggle::Game, :count)
    end

    it "leaves other servers' destinations and posted messages untouched" do
      result

      expect(TwilightStruggle::Destination.find_by(id: other_destination.id)).to be_present
      expect(TwilightStruggle::PostedMessage.find_by(id: other_posted_message.id)).to be_present
    end
  end

  context "reminder handling" do
    let(:guild_id) { config.discord_id }
    let!(:channel_reminder) { create(:reminder, server_id: guild_id, deliver_via_dm: false) }
    let!(:dm_reminder) { create(:reminder, server_id: guild_id, deliver_via_dm: true) }
    let!(:other_guild_reminder) { create(:reminder, server_id: guild_id + 1, deliver_via_dm: false) }

    it "deletes channel-bound reminders for the guild" do
      result

      expect(Reminders::Reminder.find_by(id: channel_reminder.id)).to be_nil
    end

    it "keeps DM reminders for the guild but nulls their server_id" do
      result

      dm_reminder.reload
      expect(dm_reminder).to be_present
      expect(dm_reminder.server_id).to be_nil
    end

    it "leaves reminders for other guilds untouched" do
      result

      other_guild_reminder.reload
      expect(other_guild_reminder.server_id).to eq(guild_id + 1)
    end

    context "when force_dm_reminders is true" do
      let!(:config) { create(:server_configuration, force_dm_reminders: true) }

      it "flips channel-bound reminders to deliver_via_dm instead of deleting them" do
        result

        channel_reminder.reload
        expect(channel_reminder).to be_present
        expect(channel_reminder.deliver_via_dm).to be(true)
      end

      it "nulls server_id on channel-bound reminders" do
        result

        channel_reminder.reload
        expect(channel_reminder.server_id).to be_nil
      end

      it "also nulls server_id on DM reminders" do
        result

        dm_reminder.reload
        expect(dm_reminder.server_id).to be_nil
      end
    end
  end
end
