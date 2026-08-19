# frozen_string_literal: true

require "rails_helper"

RSpec.describe Finders::TwilightStruggle::OrganiserServers do
  subject(:discord_ids) { described_class.discord_ids_for(discord_id) }

  let(:discord_id) { 700_000_000_000_000_001 }
  let(:server_configuration) { create(:server_configuration) }
  let(:tournament) { create(:twilight_struggle_tournament) }
  let(:plugin) { create(:plugin, key: "twilight_struggle", name: "Twilight Struggle") }

  let!(:tournament_admin) { create(:twilight_struggle_tournament_admin, tournament:, discord_id:) }

  let!(:bespoke_plugin_grant) do
    create(:bespoke_plugin_grant, server_configuration:, plugin_key: TwilightStruggle::PLUGIN_KEY.to_s)
  end

  let!(:plugin_activation) do
    create(:plugin_activation, server_configuration:, plugin:, enabled: true)
  end

  context "when the server is granted and the plugin is enabled" do
    it "returns the server's discord_id" do
      expect(discord_ids).to contain_exactly(server_configuration.discord_id)
    end

    it "does not require a destination to any tournament the user administers" do
      expect(TwilightStruggle::Destination.count).to eq(0)
      expect(discord_ids).to contain_exactly(server_configuration.discord_id)
    end
  end

  context "when the plugin is not enabled" do
    let(:plugin_activation) { create(:plugin_activation, server_configuration:, plugin:, enabled: false) }

    it "does not return the server's discord_id" do
      expect(discord_ids).to be_empty
    end
  end

  context "when the server has an enabled activation but no bespoke grant" do
    before { bespoke_plugin_grant.destroy }

    it "does not return the server's discord_id" do
      expect(discord_ids).to be_empty
    end
  end

  context "when the user has no admin rows anywhere" do
    let(:tournament_admin) { nil }

    it "returns an empty Set" do
      expect(discord_ids).to eq(Set.new)
      expect(discord_ids).to be_a(Set)
    end
  end

  context "when a different plugin has a disabled activation on the same server" do
    let(:other_plugin) { create(:plugin, key: "roles", name: "Roles") }

    let!(:other_plugin_activation) do
      create(:plugin_activation, server_configuration:, plugin: other_plugin, enabled: false)
    end

    it "still returns the granted, enabled server" do
      expect(discord_ids).to contain_exactly(server_configuration.discord_id)
    end
  end
end
