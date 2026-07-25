# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Twilight Struggle config", type: :request do
  include_context "discord auth"

  let(:guild) { Bot::Discord::Guild.new(id: 900_000_101, name: "Dev Refuge", owner: true, permissions: 0, icon: nil, member_count: 5) }
  let(:config) { ServerConfiguration.find_by(discord_id: guild.id) }
  let(:tournament) { create(:twilight_struggle_tournament, name: "OTSL 2026") }

  context "when signed out" do
    it "redirects to the sign-in page" do
      get twilight_struggle_tournaments_path
      expect(response).to redirect_to(root_path)
    end
  end

  context "when signed in without a granted server" do
    before do
      create(:server_configuration, discord_id: guild.id, name: "Dev Refuge")
      allow(Bot::Discord::UserGuilds).to receive(:call).and_return([guild])
      post "/auth/discord/callback"
    end

    it "redirects to the server picker with an alert" do
      get twilight_struggle_tournaments_path
      expect(response).to redirect_to(servers_path)
      expect(flash[:alert]).to be_present
    end
  end

  context "when signed in with a granted server" do
    before do
      create(:server_configuration, discord_id: guild.id, name: "Dev Refuge")
      create(:bespoke_plugin_grant, server_configuration: config, plugin_key: "twilight_struggle")
      create(:server_channel, server_configuration: config, discord_id: 4242, name: "results")
      allow(Bot::Discord::UserGuilds).to receive(:call).and_return([guild])
      post "/auth/discord/callback"
    end

    describe "the server dashboard" do
      it "links the granted plugin to the standalone tournament list" do
        get server_path(guild.id)
        expect(response.body).to include(twilight_struggle_tournaments_path)
      end
    end

    describe "GET /twilight-struggle/tournaments" do
      before { tournament }

      it "lists unclaimed tournaments with a claim form" do
        get twilight_struggle_tournaments_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("OTSL 2026")
        expect(response.body).to include(twilight_struggle_tournament_claim_path(tournament))
      end

      context "with a tournament claimed by another server" do
        let!(:elsewhere) { create(:twilight_struggle_tournament, name: "Not yours", server_configuration: create(:server_configuration)) }

        it "hides it" do
          get twilight_struggle_tournaments_path
          expect(response.body).not_to include("Not yours")
        end
      end

      context "with an archived tournament" do
        let!(:old_cup) { create(:twilight_struggle_tournament, name: "Old cup", archived_at: 1.day.ago) }

        it "hides it by default" do
          get twilight_struggle_tournaments_path
          expect(response.body).not_to include("Old cup")
        end

        it "shows it on the archived tab" do
          get twilight_struggle_tournaments_path(archived: 1)
          expect(response.body).to include("Old cup")
        end
      end
    end

    describe "POST /twilight-struggle/tournaments/:tournament_id/claim" do
      subject(:claim) do
        post twilight_struggle_tournament_claim_path(tournament), params: {server_configuration_id: config.id}
      end

      it "claims the tournament for the server" do
        claim
        expect(tournament.reload.server_configuration).to eq(config)
      end

      it "sends the user straight to the settings page" do
        claim
        expect(response).to redirect_to(edit_twilight_struggle_tournament_path(tournament))
      end

      context "when the target server is not one the user manages" do
        let(:other_server) { create(:server_configuration) }

        it "is not found" do
          post twilight_struggle_tournament_claim_path(tournament), params: {server_configuration_id: other_server.id}
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when the tournament is already claimed" do
        let(:tournament) { create(:twilight_struggle_tournament, server_configuration: create(:server_configuration)) }

        it "is not found" do
          claim
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    describe "DELETE /twilight-struggle/tournaments/:tournament_id/claim" do
      let(:tournament) { create(:twilight_struggle_tournament, server_configuration: config, discord_channel_id: 4242) }

      it "releases the tournament and clears its channel" do
        delete twilight_struggle_tournament_claim_path(tournament)
        tournament.reload
        expect(tournament.server_configuration).to be_nil
        expect(tournament.discord_channel_id).to be_nil
      end

      context "when the tournament belongs to another server" do
        let(:tournament) { create(:twilight_struggle_tournament, server_configuration: create(:server_configuration)) }

        it "is not found" do
          delete twilight_struggle_tournament_claim_path(tournament)
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    describe "GET /twilight-struggle/tournaments/:id/edit" do
      let(:tournament) { create(:twilight_struggle_tournament, name: "OTSL 2026", server_configuration: config) }

      it "renders the three template editors and the token reference" do
        get edit_twilight_struggle_tournament_path(tournament)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("tournament[template_win]")
        expect(response.body).to include("tournament[template_tie]")
        expect(response.body).to include("tournament[template_video]")
        expect(response.body).to include("{winning_player}")
      end

      it "offers the server's channels as the destination" do
        get edit_twilight_struggle_tournament_path(tournament)
        expect(response.body).to include("results")
      end

      it "shows the inherited default as the placeholder" do
        get edit_twilight_struggle_tournament_path(tournament)
        expect(response.body).to include(I18n.t("twilight_struggle.default_template.win"))
      end

      context "when the tournament is unclaimed" do
        let(:tournament) { create(:twilight_struggle_tournament) }

        it "redirects back to the list" do
          get edit_twilight_struggle_tournament_path(tournament)
          expect(response).to redirect_to(twilight_struggle_tournaments_path)
        end
      end

      context "when the tournament belongs to another server" do
        let(:tournament) { create(:twilight_struggle_tournament, server_configuration: create(:server_configuration)) }

        it "redirects back to the list" do
          get edit_twilight_struggle_tournament_path(tournament)
          expect(response).to redirect_to(twilight_struggle_tournaments_path)
        end
      end
    end

    describe "PATCH /twilight-struggle/tournaments/:id" do
      subject(:save_settings) do
        patch twilight_struggle_tournament_path(tournament), params: {tournament: attributes}
      end

      let(:tournament) { create(:twilight_struggle_tournament, server_configuration: config) }
      let(:attributes) do
        {
          discord_channel_id: "4242",
          template_win: "{winning_name} took it",
          template_tie: "",
          template_video: "",
          ping_players: "1",
          archived: "0"
        }
      end

      it "saves the settings" do
        save_settings
        tournament.reload
        expect(tournament.discord_channel_id).to eq(4242)
        expect(tournament.template_win).to eq("{winning_name} took it")
        expect(tournament.ping_players).to be(true)
      end

      it "redirects back to the settings page" do
        save_settings
        expect(response).to redirect_to(edit_twilight_struggle_tournament_path(tournament))
      end

      context "when the channel belongs to a different guild" do
        let(:attributes) { super().merge(discord_channel_id: "9999") }

        it "is not found" do
          save_settings
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when clearing the channel back to inherit" do
        let(:tournament) { create(:twilight_struggle_tournament, server_configuration: config, discord_channel_id: 4242) }
        let(:attributes) { super().merge(discord_channel_id: "") }

        it "is allowed" do
          save_settings
          expect(tournament.reload.discord_channel_id).to be_nil
        end
      end
    end
  end
end
