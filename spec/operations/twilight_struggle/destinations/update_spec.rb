# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::TwilightStruggle::Destinations::Update do
  subject(:result) { described_class.call(destination:, **attributes) }

  let(:server_configuration) { create(:server_configuration) }
  let(:tournament) { create(:twilight_struggle_tournament) }
  let(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:) }
  let!(:plugin) { create(:plugin, key: "twilight_struggle", name: "Twilight Struggle") }
  let!(:grant) { create(:bespoke_plugin_grant, server_configuration:, plugin_key: "twilight_struggle") }
  let(:attributes) do
    {
      enabled: "1",
      discord_channel_id: "555",
      template_win: "{winning_player} won",
      template_tie: "",
      template_video: "",
      ping_players: "1",
      archived: "0"
    }
  end

  before do
    allow(Bot::ConfigBus).to receive(:sync_commands)
  end

  it "succeeds" do
    expect(result).to be_success
  end

  it "returns the plugin activation, like the other plugin config ops" do
    expect(result.value).to be_a(PluginActivation)
  end

  it "stores the channel" do
    result
    expect(destination.reload.discord_channel_id).to eq(555)
  end

  it "stores a filled template" do
    result
    expect(destination.reload.template_win).to eq("{winning_player} won")
  end

  it "leaves a blank template nil so it inherits" do
    result
    expect(destination.reload.template_tie).to be_nil
  end

  describe "a template that came back exactly as it was pre-filled" do
    let(:attributes) { super().merge(template_win: I18n.t("twilight_struggle.default_template.win")) }

    it "is not stored as an override" do
      result
      expect(destination.reload.template_win).to be_nil
    end

    context "when the tournament hangs under a parent this server also has wording for" do
      let(:parent) { create(:twilight_struggle_tournament) }
      let(:tournament) { create(:twilight_struggle_tournament, parent:) }
      let!(:parent_destination) do
        create(:twilight_struggle_destination, tournament: parent, server_configuration:, template_win: "{winning_name} takes it")
      end
      let(:attributes) { super().merge(template_win: "{winning_name} takes it") }

      it "keeps following the parent rather than freezing a copy" do
        result
        expect(destination.reload.template_win).to be_nil
      end

      it "stores an edit that differs from the parent" do
        described_class.call(**attributes.merge(destination:, template_win: "{winning_name} smashed it"))
        expect(destination.reload.template_win).to eq("{winning_name} smashed it")
      end
    end
  end

  it "never touches the tournament" do
    result
    expect(destination.reload.tournament).to eq(tournament)
  end

  describe "the enable toggle" do
    it "enables the plugin for the server" do
      result
      expect(server_configuration.reload.enabled_plugin_keys).to include(:twilight_struggle)
    end

    it "resyncs the guild commands" do
      result
      expect(Bot::ConfigBus).to have_received(:sync_commands).with(server_configuration)
    end

    context "when switched off" do
      let(:attributes) { super().merge(enabled: "0") }

      it "disables the plugin" do
        result
        expect(server_configuration.reload.enabled_plugin_keys).not_to include(:twilight_struggle)
      end

      it "still saves the destination settings" do
        result
        expect(destination.reload.discord_channel_id).to eq(555)
      end
    end

    context "when the server has no grant" do
      let!(:grant) { nil }

      it "fails" do
        expect(result).to be_failure
      end

      it "leaves the destination untouched" do
        result
        expect(destination.reload.discord_channel_id).to be_nil
      end
    end
  end

  describe "the ping preference" do
    context "when set to mention" do
      it "stores true" do
        result
        expect(destination.reload.ping_players).to be(true)
      end
    end

    context "when set to names" do
      let(:attributes) { super().merge(ping_players: "0") }

      it "stores false" do
        result
        expect(destination.reload.ping_players).to be(false)
      end
    end

    context "when left on inherit" do
      let(:attributes) { super().merge(ping_players: "") }
      let(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:, ping_players: true) }

      it "clears the override back to nil" do
        result
        expect(destination.reload.ping_players).to be_nil
      end
    end
  end

  describe "archiving" do
    context "when archived is checked" do
      let(:attributes) { super().merge(archived: "1") }

      it "stamps archived_at" do
        result
        expect(destination.reload.archived_at).to be_present
      end
    end

    context "when archived is checked on an already-archived destination" do
      let(:attributes) { super().merge(archived: "1") }
      let(:archived_at) { 3.days.ago }
      let(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:, archived_at:) }

      it "keeps the original timestamp" do
        result
        expect(destination.reload.archived_at).to be_within(1.second).of(archived_at)
      end
    end

    context "when archived is unchecked on an archived destination" do
      let(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:, archived_at: 3.days.ago) }

      it "clears archived_at" do
        result
        expect(destination.reload.archived_at).to be_nil
      end
    end

    context "when a different server subscribes to the same tournament" do
      let(:other_server) { create(:server_configuration) }
      let!(:other_destination) { create(:twilight_struggle_destination, tournament:, server_configuration: other_server) }
      let(:attributes) { super().merge(archived: "1") }

      it "archiving one server's destination leaves the other's untouched" do
        result
        expect(other_destination.reload.archived_at).to be_nil
      end
    end
  end
end
