# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::TwilightStruggle::Destinations::Save do
  subject(:result) { described_class.call(destination:, **attributes) }

  let(:server_configuration) { create(:server_configuration) }
  let(:tournament) { create(:twilight_struggle_tournament) }
  let(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:) }
  let(:attributes) do
    {
      discord_channel_id: "555",
      template_win: "{winning_player} won",
      template_tie: "",
      template_video: "",
      ping_players: "1",
      archived: "0"
    }
  end

  it "succeeds" do
    expect(result).to be_success
  end

  it "returns the destination" do
    expect(result.value).to eq(destination)
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

  it "never touches the tournament" do
    result
    expect(destination.reload.tournament).to eq(tournament)
  end

  describe "a destination that does not exist yet" do
    let(:destination) { server_configuration.twilight_struggle_destinations.new(tournament:) }

    it "subscribes the server" do
      expect { result }.to change(TwilightStruggle::Destination, :count).by(1)
    end

    it "stores the submitted settings on the new row" do
      result
      expect(destination.reload.discord_channel_id).to eq(555)
    end

    context "with nothing submitted" do
      let(:attributes) { {} }

      it "subscribes with everything left to inherit" do
        result
        expect(destination.reload.discord_channel_id).to be_nil
        expect(destination.template_win).to be_nil
      end
    end

    context "when the server already subscribes to the tournament" do
      let!(:existing) { create(:twilight_struggle_destination, tournament:, server_configuration:) }

      it "fails rather than subscribing twice" do
        expect(result).to be_failure
        expect(TwilightStruggle::Destination.where(tournament:, server_configuration:).count).to eq(1)
      end
    end
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
