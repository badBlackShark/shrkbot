# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Servers::TwilightStruggle", type: :request do
  include_context "discord auth"

  let(:guild) { Bot::Discord::Guild.new(id: 900_000_201, name: "Dev Refuge", owner: true, permissions: 0, icon: nil, member_count: 5) }
  let(:config) { ServerConfiguration.find_by(discord_id: guild.id) }
  let(:turbo) { {headers: {"Accept" => "text/vnd.turbo-stream.html"}} }
  let(:tournament) { create(:twilight_struggle_tournament, name: "OTSL 2026") }

  context "when signed out" do
    it "redirects to the sign-in page" do
      get server_twilight_struggle_path(guild.id)
      expect(response).to redirect_to(root_path)
    end
  end

  context "when signed in" do
    before do
      create(:server_configuration, discord_id: guild.id, name: "Dev Refuge")
      create(:plugin, key: "twilight_struggle", name: "Twilight Struggle")
      allow(Bot::ConfigBus).to receive(:sync_commands)
      allow(Bot::Discord::UserGuilds).to receive(:call).and_return([guild])
      post "/auth/discord/callback"
    end

    context "when the server has not been granted the plugin" do
      it "redirects to the server dashboard" do
        get server_twilight_struggle_path(guild.id)
        expect(response).to redirect_to(server_path(guild.id))
        expect(flash[:alert]).to eq(I18n.t("servers.unknown_plugin"))
      end
    end

    context "when the server holds the grant" do
      before do
        create(:bespoke_plugin_grant, server_configuration: config, plugin_key: "twilight_struggle")
        create(:server_channel, server_configuration: config, discord_id: 4242, name: "results")
      end

      describe "GET /servers/:server_id/twilight_struggle" do
        it "renders the empty state with nothing to show" do
          get server_twilight_struggle_path(guild.id)
          expect(response).to have_http_status(:ok)
          expect(response.body).to include(I18n.t("views.servers.twilight_struggle.show.empty_body"))
        end

        it "renders a different empty state on the archived tab" do
          get server_twilight_struggle_path(guild.id, archived: 1)
          expect(response.body).to include(I18n.t("views.servers.twilight_struggle.show.empty_archived"))
        end

        context "with tournaments to show" do
          before { tournament }

          it "lists tournaments with a subscribe link" do
            get server_twilight_struggle_path(guild.id)
            expect(response.body).to include("OTSL 2026")
            expect(response.body).to include(server_twilight_struggle_destinations_path(guild.id, tournament_id: tournament.id))
          end

          context "with a tournament this server subscribes to" do
            let!(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration: config) }

            it "offers configure and unsubscribe instead of a subscribe link" do
              get server_twilight_struggle_path(guild.id)
              expect(response.body).to include(edit_server_twilight_struggle_destination_path(guild.id, destination))
              expect(response.body).to include(I18n.t("components.twilight_struggle.destination_actions.unsubscribe"))
            end
          end

          context "with a tournament another server subscribes to" do
            let!(:other_destination) { create(:twilight_struggle_destination, tournament:, server_configuration: create(:server_configuration)) }

            it "still lists it here, unsubscribed" do
              get server_twilight_struggle_path(guild.id)
              expect(response.body).to include("OTSL 2026")
              expect(response.body).to include(server_twilight_struggle_destinations_path(guild.id, tournament_id: tournament.id))
              expect(response.body).not_to include(edit_server_twilight_struggle_destination_path(guild.id, other_destination))
            end
          end

          context "with an archived destination" do
            let!(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration: config, archived_at: 1.day.ago) }

            it "hides it by default" do
              get server_twilight_struggle_path(guild.id)
              expect(response.body).not_to include("OTSL 2026")
            end

            it "shows it on the archived tab" do
              get server_twilight_struggle_path(guild.id, archived: 1)
              expect(response.body).to include("OTSL 2026")
            end
          end

          context "with a tournament the site closed" do
            let!(:tournament) { create(:twilight_struggle_tournament, name: "Done cup", status: "closed") }

            it "shows it on the archived tab" do
              get server_twilight_struggle_path(guild.id, archived: 1)
              expect(response.body).to include(I18n.t("components.twilight_struggle.tournament_row.closed"))
            end
          end
        end
      end

      describe "PATCH /servers/:server_id/twilight_struggle" do
        it "toggles the plugin and returns a turbo stream on success" do
          patch server_twilight_struggle_path(guild.id), params: {twilight_struggle: {enabled: "1"}}, **turbo
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
          expect(config.plugins.enabled.exists?(key: :twilight_struggle)).to be(true)
        end

        it "falls back to a redirect without Turbo" do
          patch server_twilight_struggle_path(guild.id), params: {twilight_struggle: {enabled: "0"}}
          expect(response).to redirect_to(server_twilight_struggle_path(guild.id))
        end
      end

      describe "POST /servers/:server_id/twilight_struggle/destinations" do
        subject(:subscribe) do
          post server_twilight_struggle_destinations_path(guild.id), params: {tournament_id: tournament.id}
        end

        it "subscribes the server to the tournament" do
          subscribe
          expect(TwilightStruggle::Destination.find_by(tournament:, server_configuration: config)).to be_present
        end

        it "redirects to the destination's edit page" do
          subscribe
          destination = TwilightStruggle::Destination.find_by(tournament:, server_configuration: config)
          expect(response).to redirect_to(edit_server_twilight_struggle_destination_path(guild.id, destination))
        end

        context "when the tournament does not exist" do
          it "is not found" do
            post server_twilight_struggle_destinations_path(guild.id), params: {tournament_id: "tst_nope"}
            expect(response).to have_http_status(:not_found)
          end
        end
      end

      describe "DELETE /servers/:server_id/twilight_struggle/destinations/:id" do
        let!(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration: config) }

        it "unsubscribes the server" do
          delete server_twilight_struggle_destination_path(guild.id, destination)
          expect(TwilightStruggle::Destination.exists?(destination.id)).to be(false)
        end

        it "redirects back to the list" do
          delete server_twilight_struggle_destination_path(guild.id, destination)
          expect(response).to redirect_to(server_twilight_struggle_path(guild.id))
        end
      end

      describe "GET /servers/:server_id/twilight_struggle/destinations/:id/edit" do
        let!(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration: config) }

        it "renders the three template editors and the token reference" do
          get edit_server_twilight_struggle_destination_path(guild.id, destination)
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("destination[template_win]")
          expect(response.body).to include("destination[template_tie]")
          expect(response.body).to include("destination[template_video]")
          expect(response.body).to include("{winning_player}")
        end

        it "offers the server's channels as the destination" do
          get edit_server_twilight_struggle_destination_path(guild.id, destination)
          expect(response.body).to include("results")
        end

        it "offers the enable toggle in the page header" do
          get edit_server_twilight_struggle_destination_path(guild.id, destination)
          expect(response.body).to include("destination[enabled]")
        end

        it "gates the settings behind the overlay while the plugin is off" do
          get edit_server_twilight_struggle_destination_path(guild.id, destination)
          expect(response.body).to include(I18n.t("components.config_page.disabled_title", plugin: I18n.t("views.servers.twilight_struggle.destinations.edit.title")))
          expect(response.body).to include(I18n.t("views.servers.twilight_struggle.destinations.edit.gate_message"))
          expect(response.body).to include("opacity-45")
        end

        context "when the plugin is enabled for the server" do
          let!(:activation) do
            create(:plugin_activation, server_configuration: config, plugin: Plugin.find_by(key: "twilight_struggle"), enabled: true)
          end

          it "lifts the overlay" do
            get edit_server_twilight_struggle_destination_path(guild.id, destination)
            expect(response.body).not_to include("opacity-45")
          end
        end

        context "when the destination belongs to another server" do
          let(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration: create(:server_configuration)) }

          it "redirects back to this server's list" do
            get edit_server_twilight_struggle_destination_path(guild.id, destination)
            expect(response).to redirect_to(server_twilight_struggle_path(guild.id))
          end
        end
      end

      describe "PATCH /servers/:server_id/twilight_struggle/destinations/:id" do
        subject(:save_settings) do
          patch server_twilight_struggle_destination_path(guild.id, destination), params: {destination: attributes}
        end

        let!(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration: config) }
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
          destination.reload
          expect(destination.discord_channel_id).to eq(4242)
          expect(destination.template_win).to eq("{winning_name} took it")
          expect(destination.ping_players).to be(true)
        end

        it "redirects back to the destination's edit page" do
          save_settings
          expect(response).to redirect_to(edit_server_twilight_struggle_destination_path(guild.id, destination))
        end

        context "when the channel belongs to a different guild" do
          let(:attributes) { super().merge(discord_channel_id: "9999") }

          it "is not found" do
            save_settings
            expect(response).to have_http_status(:not_found)
          end
        end

        context "when the destination belongs to another server" do
          let(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration: create(:server_configuration)) }

          it "redirects back to this server's list rather than saving" do
            save_settings
            expect(response).to redirect_to(server_twilight_struggle_path(guild.id))
          end
        end
      end
    end
  end
end
