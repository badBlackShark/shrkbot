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
        create(:server_channel, server_configuration: config, discord_id: 4200, name: "Tournaments", channel_type: ServerChannel::CATEGORY_TYPE)
        create(:server_channel, server_configuration: config, discord_id: 4242, name: "results", parent_id: 4200)
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

          it "offers configure whether or not the server subscribes" do
            get server_twilight_struggle_path(guild.id)
            expect(response.body).to include(edit_server_twilight_struggle_destination_path(guild.id, tournament))
          end

          context "with a tournament this server subscribes to" do
            let!(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration: config) }

            it "offers unsubscribe instead of subscribe" do
              get server_twilight_struggle_path(guild.id)
              expect(response.body).to include(I18n.t("components.twilight_struggle.destination_actions.unsubscribe"))
              expect(response.body).not_to include(server_twilight_struggle_destinations_path(guild.id, tournament_id: tournament.id))
            end

            it "names the channel it posts in, under its category" do
              destination.update!(discord_channel_id: 4242)
              get server_twilight_struggle_path(guild.id)
              expect(response.body).to include("Tournaments / #results")
            end
          end

          context "with a tournament another server subscribes to" do
            let!(:other_destination) do
              create(:twilight_struggle_destination, tournament:, server_configuration: create(:server_configuration), discord_channel_id: 7777)
            end

            it "still lists it here, unsubscribed and without the other server's channel" do
              get server_twilight_struggle_path(guild.id)
              expect(response.body).to include("OTSL 2026")
              expect(response.body).to include(server_twilight_struggle_destinations_path(guild.id, tournament_id: tournament.id))
              expect(response.body).not_to include("7777")
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

        it "redirects to the tournament's settings page" do
          subscribe
          expect(response).to redirect_to(edit_server_twilight_struggle_destination_path(guild.id, tournament))
        end

        context "when the tournament does not exist" do
          it "is not found" do
            post server_twilight_struggle_destinations_path(guild.id), params: {tournament_id: "tst_nope"}
            expect(response).to have_http_status(:not_found)
          end
        end

        context "when the server already subscribes to the tournament" do
          let!(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration: config) }

          it "does not subscribe twice" do
            expect { subscribe }.not_to change(TwilightStruggle::Destination, :count)
          end
        end
      end

      describe "DELETE /servers/:server_id/twilight_struggle/destinations/:tournament_id" do
        let!(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration: config) }

        it "unsubscribes the server" do
          delete server_twilight_struggle_destination_path(guild.id, tournament)
          expect(TwilightStruggle::Destination.exists?(destination.id)).to be(false)
        end

        it "redirects back to the list" do
          delete server_twilight_struggle_destination_path(guild.id, tournament)
          expect(response).to redirect_to(server_twilight_struggle_path(guild.id))
        end
      end

      describe "GET /servers/:server_id/twilight_struggle/destinations/:tournament_id/edit" do
        let!(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration: config) }

        it "renders the three template editors and the token reference" do
          get edit_server_twilight_struggle_destination_path(guild.id, tournament)
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("destination[template_win]")
          expect(response.body).to include("destination[template_tie]")
          expect(response.body).to include("destination[template_video]")
          expect(response.body).to include("{winning_player}")
        end

        it "offers the server's channels as the destination" do
          get edit_server_twilight_struggle_destination_path(guild.id, tournament)
          expect(response.body).to include("results")
        end

        it "offers the subscription toggle in the page header, switched on" do
          get edit_server_twilight_struggle_destination_path(guild.id, tournament)
          expect(response.body).to include("destination[subscribed]")
          expect(response.body).to include(I18n.t("components.config_page.enabled"))
        end

        it "gates the settings behind the overlay while the plugin is off" do
          get edit_server_twilight_struggle_destination_path(guild.id, tournament)
          expect(response.body).to include(I18n.t("views.servers.twilight_struggle.destinations.edit.prereq_gate_title"))
          expect(response.body).to include("opacity-45")
        end

        context "when the plugin is enabled for the server" do
          let!(:activation) do
            create(:plugin_activation, server_configuration: config, plugin: Plugin.find_by(key: "twilight_struggle"), enabled: true)
          end

          it "lifts the overlay" do
            get edit_server_twilight_struggle_destination_path(guild.id, tournament)
            expect(response.body).not_to include("opacity-45")
          end
        end

        context "when the server does not subscribe to the tournament" do
          let!(:destination) { nil }

          it "still opens, so the channel and wording can be set up first" do
            get edit_server_twilight_struggle_destination_path(guild.id, tournament)
            expect(response).to have_http_status(:ok)
            expect(response.body).to include("destination[template_win]")
          end

          it "shows the subscription toggle switched off" do
            get edit_server_twilight_struggle_destination_path(guild.id, tournament)
            expect(response.body).to include(I18n.t("components.config_page.disabled"))
          end
        end

        context "when another server subscribes to the same tournament" do
          let!(:destination) { nil }
          let!(:elsewhere) do
            create(:twilight_struggle_destination, tournament:, server_configuration: create(:server_configuration), discord_channel_id: 7777)
          end

          it "shows this server's settings, never the other server's" do
            get edit_server_twilight_struggle_destination_path(guild.id, tournament)
            expect(response.body).not_to include("7777")
          end
        end

        context "when the tournament does not exist" do
          it "is not found" do
            get edit_server_twilight_struggle_destination_path(guild.id, "tst_nope")
            expect(response).to have_http_status(:not_found)
          end
        end
      end

      describe "PATCH /servers/:server_id/twilight_struggle/destinations/:tournament_id" do
        subject(:save_settings) do
          patch server_twilight_struggle_destination_path(guild.id, tournament), params: {destination: attributes}
        end

        let!(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration: config) }
        let(:attributes) do
          {
            subscribed: "1",
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
          expect(response).to redirect_to(edit_server_twilight_struggle_destination_path(guild.id, tournament))
        end

        context "when the channel belongs to a different guild" do
          let(:attributes) { super().merge(discord_channel_id: "9999") }

          it "is not found" do
            save_settings
            expect(response).to have_http_status(:not_found)
          end
        end

        context "when the subscription toggle comes back off" do
          let(:attributes) { super().merge(subscribed: "0") }

          it "unsubscribes the server" do
            save_settings
            expect(TwilightStruggle::Destination.exists?(destination.id)).to be(false)
          end

          it "still redirects back to the settings page" do
            save_settings
            expect(response).to redirect_to(edit_server_twilight_struggle_destination_path(guild.id, tournament))
          end
        end

        context "when the server does not subscribe yet" do
          let!(:destination) { nil }

          it "subscribes it with the submitted settings" do
            expect { save_settings }.to change(TwilightStruggle::Destination, :count).by(1)
            expect(TwilightStruggle::Destination.last.discord_channel_id).to eq(4242)
          end
        end

        context "when another server subscribes to the same tournament" do
          let!(:elsewhere) { create(:twilight_struggle_destination, tournament:, server_configuration: create(:server_configuration)) }

          it "leaves the other server's subscription alone" do
            save_settings
            expect(elsewhere.reload.discord_channel_id).to be_nil
          end
        end
      end
    end
  end
end
