# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::ServerConfiguration::Previews::ApplyPlugin do
  subject(:result) { described_class.call(server_configuration:, entry:) }

  let(:server_configuration) { Ops::ServerConfiguration::Ensure.call(discord_id: 555).value }
  let!(:plugin) { create(:plugin, key: "roles", name: "Roles") }

  context "with a settings hash and no records" do
    let(:entry) do
      {
        plugin: "roles",
        settings_association: :role_setting,
        enabled: true,
        settings: {channel_id: 104}
      }
    end

    it "applies the settings to the named association" do
      result

      expect(server_configuration.role_setting.channel_id).to eq(104)
    end

    it "flips the plugin activation" do
      result

      activation = server_configuration.plugin_activations.find_by(plugin:)
      expect(activation.enabled).to be(true)
    end
  end

  context "with nested records" do
    let(:entry) do
      {
        plugin: "roles",
        settings_association: :role_setting,
        enabled: true,
        settings: {channel_id: 104},
        records: {
          role_sets: [
            {
              name: "Pronouns",
              selection_mode: "multi",
              position: 0,
              assignable_roles: [
                {role_id: 203, position: 0},
                {role_id: 204, position: 1}
              ]
            }
          ]
        }
      }
    end

    it "builds the nested association two levels deep" do
      result

      role_set = Roles::Set.find_by!(role_setting: server_configuration.role_setting, name: "Pronouns")
      expect(role_set.assignable_roles.pluck(:role_id)).to match_array([203, 204])
    end

    it "stays idempotent by clearing the association before rebuilding" do
      result
      described_class.call(server_configuration:, entry:)

      expect(Roles::Set.where(role_setting: server_configuration.role_setting).count).to eq(1)
    end
  end

  context "with a record attribute that is an empty array" do
    let!(:plugin) { create(:plugin, key: "lfg", name: "Looking for Game") }
    let(:entry) do
      {
        plugin: "lfg",
        settings_association: :lfg_settings,
        enabled: true,
        settings: {cooldown_seconds: 300},
        records: {
          pingable_roles: [
            {role_id: 206, excluded_role_ids: []}
          ]
        }
      }
    end

    it "treats it as a scalar attribute rather than a nested association" do
      result

      expect(server_configuration.lfg_settings.pingable_roles.sole.excluded_role_ids).to eq([])
    end
  end

  context "with a plugin that has no settings row" do
    let!(:plugin) { create(:plugin, key: "integrations", name: "Integrations") }
    let!(:source_plugin) { create(:plugin, key: "steam", name: "Steam") }
    let(:entry) { {plugin: "integrations", enabled: true} }

    it "flips the plugin activation without a settings association" do
      result

      expect(server_configuration.plugin_activations.find_by(plugin:).enabled).to be(true)
    end

    context "with records that hang off the server configuration" do
      let(:integrations_entry) { {plugin: "integrations", enabled: true} }
      let(:entry) do
        {
          plugin: "steam",
          enabled: true,
          records: {
            feed_subscriptions: [
              {
                watch: {
                  find_by: {watcher: "Integrations::Steam::NewsWatcher", external_id: "440"},
                  create_with: {name: "Team Fortress 2"}
                },
                channel_id: 101,
                body_length: "full",
                subscribed_events: [
                  {event_type: "Integrations::Steam::PatchNotesPublished", role_id: 207},
                  {event_type: "Integrations::Steam::ArticlePublished"}
                ]
              }
            ]
          }
        }
      end

      before { described_class.call(server_configuration:, entry: integrations_entry) }

      it "builds the subscription with its nested events on the server configuration" do
        result

        subscription = server_configuration.feed_subscriptions.sole
        expect(subscription).to have_attributes(channel_id: 101, body_length: "full")
        expect(subscription.subscribed_events.find_by!(event_type: "Integrations::Steam::PatchNotesPublished").role_id).to eq(207)
        expect(subscription.subscribed_events.pluck(:event_type)).to match_array(
          ["Integrations::Steam::PatchNotesPublished", "Integrations::Steam::ArticlePublished"]
        )
      end

      it "creates the referenced watch with its create_with attributes" do
        result

        expect(server_configuration.feed_subscriptions.sole.watch).to have_attributes(
          watcher: "Integrations::Steam::NewsWatcher",
          external_id: "440",
          name: "Team Fortress 2"
        )
      end

      context "when the referenced watch already exists under another name" do
        let!(:existing_watch) { create(:integration_watch, external_id: "440", name: "TF2") }

        it "reuses it without renaming it" do
          result

          expect(server_configuration.feed_subscriptions.sole.watch).to eq(existing_watch)
          expect(existing_watch.reload.name).to eq("TF2")
        end
      end

      it "builds no duplicates when run twice" do
        result
        described_class.call(server_configuration:, entry:)

        expect(server_configuration.feed_subscriptions.count).to eq(1)
        expect(Integrations::Watch.where(external_id: "440").count).to eq(1)
      end
    end
  end
end
