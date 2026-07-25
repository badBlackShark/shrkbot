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

  context "when signed in as the bot owner with no granted servers" do
    let!(:tournament) { create(:twilight_struggle_tournament, name: "OTSL 2026") }

    before do
      allow(Bot::Discord::UserGuilds).to receive(:call).and_return([])
      post "/auth/discord/callback"
      allow(Bot::Config).to receive(:owner_id).and_return(User.last.discord_id.to_s)
    end

    it "still opens the list instead of bouncing to the picker" do
      get twilight_struggle_tournaments_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("OTSL 2026")
    end

    it "says there is nowhere to claim it to" do
      get twilight_struggle_tournaments_path
      expect(response.body).to include(I18n.t("components.twilight_struggle.claim_form.no_servers"))
    end
  end

  context "when signed in with a granted server" do
    before do
      create(:server_configuration, discord_id: guild.id, name: "Dev Refuge")
      create(:bespoke_plugin_grant, server_configuration: config, plugin_key: "twilight_struggle")
      create(:plugin, key: "twilight_struggle", name: "Twilight Struggle")
      allow(Bot::ConfigBus).to receive(:sync_commands)
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

    describe "GET /twilight-struggle/tournaments with nothing to show" do
      it "renders the empty state" do
        get twilight_struggle_tournaments_path
        expect(response.body).to include(I18n.t("views.twilight_struggle.tournaments.index.empty_body"))
      end

      it "renders a different empty state on the archived tab" do
        get twilight_struggle_tournaments_path(archived: 1)
        expect(response.body).to include(I18n.t("views.twilight_struggle.tournaments.index.empty_archived"))
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

      context "with a tournament this server already claimed" do
        let!(:claimed) { create(:twilight_struggle_tournament, name: "Claimed cup", server_configuration: config) }

        it "offers configure and release instead of a claim form" do
          get twilight_struggle_tournaments_path
          expect(response.body).to include(edit_twilight_struggle_tournament_path(claimed))
          expect(response.body).to include(I18n.t("components.twilight_struggle.destination_actions.release"))
        end

        it "names the destination server on the row" do
          get twilight_struggle_tournaments_path
          expect(response.body).to include("Dev Refuge")
        end
      end

      context "with a bracket under a league" do
        let!(:bracket) { create(:twilight_struggle_tournament, name: "Round of 16", parent: tournament) }

        it "names the parent on the row" do
          get twilight_struggle_tournaments_path
          expect(response.body).to include("Part of OTSL 2026")
        end
      end

      context "with the friendly-games singleton" do
        let!(:friendly) { create(:twilight_struggle_tournament, :friendly) }

        it "badges it as friendlies" do
          get twilight_struggle_tournaments_path
          expect(response.body).to include(I18n.t("components.twilight_struggle.tournament_row.friendly"))
        end
      end

      context "with a tournament the site closed" do
        let!(:closed) { create(:twilight_struggle_tournament, name: "Done cup", status: "closed") }

        it "badges it as closed on the archived tab" do
          get twilight_struggle_tournaments_path(archived: 1)
          expect(response.body).to include(I18n.t("components.twilight_struggle.tournament_row.closed"))
        end
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

      context "when another request wins the race and claims it first" do
        before do
          allow(Ops::TwilightStruggle::Tournaments::Claim).to receive(:call).and_return(
            Ops::ApplicationOperation::Result.new(false, tournament, ["Another server claimed this tournament first."], [])
          )
        end

        it "sends the user back to the list with the reason" do
          claim
          expect(response).to redirect_to(twilight_struggle_tournaments_path)
          expect(flash[:alert]).to eq("Another server claimed this tournament first.")
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

      context "when the tournament is not claimed at all" do
        let(:tournament) { create(:twilight_struggle_tournament) }

        it "is not found" do
          delete twilight_struggle_tournament_claim_path(tournament)
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when the tournament does not exist" do
        it "is not found" do
          delete twilight_struggle_tournament_claim_path("tst_nope")
          expect(response).to have_http_status(:not_found)
        end
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

      it "renders the plugin sidebar with Twilight Struggle active" do
        get edit_twilight_struggle_tournament_path(tournament)
        expect(response.body).to include("plugin-sidebar")
        expect(response.body).to include(I18n.t("components.plugin_row.plugin.twilight_struggle.name"))
      end

      it "offers the enable toggle in the page header" do
        get edit_twilight_struggle_tournament_path(tournament)
        expect(response.body).to include("tournament[enabled]")
      end

      it "gates the settings behind the overlay while the plugin is off" do
        get edit_twilight_struggle_tournament_path(tournament)
        expect(response.body).to include(I18n.t("components.config_page.disabled_title", plugin: I18n.t("views.twilight_struggle.tournaments.edit.title")))
        expect(response.body).to include(I18n.t("views.twilight_struggle.tournaments.edit.gate_message"))
        expect(response.body).to include("opacity-45")
      end

      context "when the plugin is enabled for the server" do
        let!(:activation) do
          create(:plugin_activation, server_configuration: config, plugin: Plugin.find_by(key: "twilight_struggle"), enabled: true)
        end

        it "lifts the overlay" do
          get edit_twilight_struggle_tournament_path(tournament)
          expect(response.body).not_to include("opacity-45")
        end

        it "shows the toggle as on" do
          get edit_twilight_struggle_tournament_path(tournament)
          expect(response.body).to include(I18n.t("components.config_page.enabled"))
        end
      end

      context "when the tournament is unclaimed" do
        let(:tournament) { create(:twilight_struggle_tournament) }

        it "redirects back to the list" do
          get edit_twilight_struggle_tournament_path(tournament)
          expect(response).to redirect_to(twilight_struggle_tournaments_path)
        end
      end

      context "when the tournament does not exist" do
        it "redirects back to the list" do
          get edit_twilight_struggle_tournament_path("tst_nope")
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
          enabled: "1",
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

      context "when Turbo submits the form" do
        subject(:save_settings) do
          patch twilight_struggle_tournament_path(tournament),
            params: {tournament: attributes},
            headers: {"Accept" => "text/vnd.turbo-stream.html"}
        end

        it "replaces the form and the sidebar in place" do
          save_settings
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("twilight_struggle-config")
          expect(response.body).to include("plugin-sidebar")
        end

        it "saves the settings" do
          save_settings
          expect(tournament.reload.discord_channel_id).to eq(4242)
        end
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
