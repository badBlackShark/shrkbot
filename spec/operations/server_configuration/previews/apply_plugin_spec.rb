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
end
