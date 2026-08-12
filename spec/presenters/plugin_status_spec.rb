# frozen_string_literal: true

require "rails_helper"

RSpec.describe PluginStatus do
  describe ".rows" do
    subject(:rows) { described_class.rows(server_configuration, access:) }

    include_context "with a bespoke plugin definition"

    let(:server_configuration) { create(:server_configuration) }
    let(:user) { create(:user) }
    let(:access) { PluginAccess.new(user:, server_configuration:, manages_server: true) }

    it "omits an ungranted bespoke plugin" do
      expect(rows.map(&:key)).not_to include(:bespoke_thing)
    end

    context "when the bespoke plugin is granted" do
      before { create(:bespoke_plugin_grant, server_configuration:, plugin_key: bespoke_definition.key) }

      it "includes it" do
        expect(rows.map(&:key)).to include(:bespoke_thing)
      end

      it "flags it as bespoke" do
        expect(rows.select(&:bespoke).map(&:key)).to eq([:bespoke_thing])
      end

      it "lists it before every plugin any server can have" do
        expect(rows.first.key).to eq(:bespoke_thing)
      end
    end

    context "when the policy denies the user management of the server" do
      let(:access) { PluginAccess.new(user:, server_configuration:, manages_server: false) }

      it "marks the rows as not manageable" do
        expect(rows.map(&:manageable)).to all(be(false))
      end
    end

    it "mirrors the policy's toggle decision on every catalog and global row" do
      expect(rows.map(&:toggleable)).to eq(rows.map { |row| access.toggle?(row.key) })
    end

    it "sorts the fully manageable set alphabetically by translated plugin name" do
      names = rows.map { |row| I18n.t("components.plugin_row.plugin.#{row.key}.name") }

      expect(names).to eq(names.sort)
    end

    context "when the user can manage only one plugin as a tournament organiser" do
      let(:access) { PluginAccess.new(user:, server_configuration:, manages_server: false) }
      let(:twilight_struggle_plugin) { create(:plugin, key: "twilight_struggle", name: "Twilight Struggle") }

      before do
        create(:twilight_struggle_tournament_admin, discord_id: user.discord_id)
        create(:bespoke_plugin_grant, server_configuration:, plugin_key: TwilightStruggle::PLUGIN_KEY.to_s)
        create(:plugin_activation, server_configuration:, plugin: twilight_struggle_plugin, enabled: true)
      end

      it "puts the manageable plugin before every unmanageable one" do
        expect(rows.map(&:manageable)).to eq([true] + [false] * (rows.size - 1))
      end

      it "sorts each group alphabetically by translated plugin name" do
        manageable_names, unmanageable_names = rows.partition(&:manageable).map { |group| group.map { |row| I18n.t("components.plugin_row.plugin.#{row.key}.name") } }

        expect(manageable_names).to eq(manageable_names.sort)
        expect(unmanageable_names).to eq(unmanageable_names.sort)
      end
    end
  end
end
