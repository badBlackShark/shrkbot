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
