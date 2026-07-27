# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwilightStruggle::AdministeredServers do
  subject(:discord_ids) { described_class.discord_ids_for(discord_id) }

  let(:discord_id) { 700_000_000_000_000_001 }
  let(:server_configuration) { create(:server_configuration) }

  let!(:bespoke_plugin_grant) do
    create(:bespoke_plugin_grant, server_configuration:, plugin_key: TwilightStruggle::PLUGIN_KEY.to_s)
  end

  context "when the admin row is on a tournament the server actively subscribes to" do
    let(:tournament) { create(:twilight_struggle_tournament) }

    let!(:tournament_admin) { create(:twilight_struggle_tournament_admin, tournament:, discord_id:) }
    let!(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:, active: true) }

    it "returns the server's discord_id" do
      expect(discord_ids).to contain_exactly(server_configuration.discord_id)
    end
  end

  context "when the admin row is on a parent tournament and the server subscribes to the child" do
    let(:parent) { create(:twilight_struggle_tournament) }
    let(:child) { create(:twilight_struggle_tournament, parent:) }

    let!(:tournament_admin) { create(:twilight_struggle_tournament_admin, tournament: parent, discord_id:) }
    let!(:destination) { create(:twilight_struggle_destination, tournament: child, server_configuration:, active: true) }

    it "returns the server's discord_id" do
      expect(discord_ids).to contain_exactly(server_configuration.discord_id)
    end
  end

  context "when the admin row is on a child tournament and the server subscribes to the parent" do
    let(:parent) { create(:twilight_struggle_tournament) }
    let(:child) { create(:twilight_struggle_tournament, parent:) }

    let!(:tournament_admin) { create(:twilight_struggle_tournament_admin, tournament: child, discord_id:) }
    let!(:destination) { create(:twilight_struggle_destination, tournament: parent, server_configuration:, active: true) }

    it "does not return the server's discord_id" do
      expect(discord_ids).to be_empty
    end
  end

  context "when the destination is not active" do
    let(:tournament) { create(:twilight_struggle_tournament) }

    let!(:tournament_admin) { create(:twilight_struggle_tournament_admin, tournament:, discord_id:) }
    let!(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:, active: false) }

    it "does not return the server's discord_id" do
      expect(discord_ids).to be_empty
    end
  end

  context "when the server has no BespokePluginGrant for twilight_struggle" do
    let(:tournament) { create(:twilight_struggle_tournament) }
    let(:ungranted_server_configuration) { create(:server_configuration) }

    let!(:tournament_admin) { create(:twilight_struggle_tournament_admin, tournament:, discord_id:) }
    let!(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration: ungranted_server_configuration, active: true) }

    it "does not return the server's discord_id" do
      expect(discord_ids).to be_empty
    end
  end

  context "when the user has no admin rows" do
    it "returns an empty Set" do
      expect(discord_ids).to eq(Set.new)
      expect(discord_ids).to be_a(Set)
    end
  end
end
