# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Notifications", type: :request do
  include_context "discord auth"

  let(:guild_a) { Discord::Guild.new(id: 900_000_010, name: "Alpha Server", owner: true, permissions: 0, icon: nil, member_count: 10) }
  let(:guild_b) { Discord::Guild.new(id: 900_000_011, name: "Beta Server", owner: true, permissions: 0, icon: nil, member_count: 5) }
  let(:guild_other) { Discord::Guild.new(id: 900_000_012, name: "Other Server", owner: true, permissions: 0, icon: nil, member_count: 3) }

  let!(:config_a) { create(:server_configuration, discord_id: guild_a.id) }
  let!(:config_b) { create(:server_configuration, discord_id: guild_b.id) }
  let!(:config_other) { create(:server_configuration, discord_id: guild_other.id) }

  let!(:notif_a) { create(:notification, server_configuration: config_a, data: {"plugin_key" => "logging", "plugin_name" => "Logging", "channel_name" => "mod-log"}) }
  let!(:notif_b) { create(:notification, server_configuration: config_b, data: {"plugin_key" => "logging", "plugin_name" => "Logging", "channel_name" => "general"}) }
  let!(:notif_other) { create(:notification, server_configuration: config_other, data: {"plugin_key" => "logging", "plugin_name" => "Logging", "channel_name" => "chat"}) }

  context "when signed out" do
    it "redirects to root" do
      get notifications_path
      expect(response).to redirect_to(root_path)
    end
  end

  context "when signed in" do
    before do
      post "/auth/discord/callback"
      # Authorize guild_a and guild_b but NOT guild_other
      allow(Discord::UserGuilds).to receive(:call).and_return([guild_a, guild_b])
      get server_path(guild_a.id)
    end

    describe "GET /notifications" do
      it "renders a turbo frame with the bell" do
        get notifications_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("notifications")
      end

      it "includes notifications from authorized servers" do
        get notifications_path
        expect(response.body).to include("mod-log was deleted")
        expect(response.body).to include("general was deleted")
      end

      it "excludes notifications from non-authorized servers" do
        get notifications_path
        expect(response.body).not_to include("chat was deleted")
      end

      context "with open param" do
        it "renders the details element with the open attribute" do
          get notifications_path(open: true)
          expect(response.body).to match(/<details[^>]*\bopen\b/)
        end
      end

      context "without open param" do
        it "renders the details element without the open attribute" do
          get notifications_path
          expect(response.body).not_to match(/<details[^>]*\bopen\b/)
        end
      end

      context "with server_id param (this-server scope)" do
        it "shows only notifications for that server" do
          get notifications_path(server_id: guild_a.id)
          expect(response.body).to include("mod-log was deleted")
          expect(response.body).not_to include("general was deleted")
        end
      end

      context "with a server context but the all-servers scope" do
        it "shows notifications from every authorized server" do
          get notifications_path(server_id: guild_a.id, scope: "all")
          expect(response.body).to include("mod-log was deleted")
          expect(response.body).to include("general was deleted")
        end
      end

      context "the scope toggle" do
        it "renders both scope links when a server context is present" do
          get notifications_path(server_id: guild_a.id)
          expect(response.body).to include("scope=server")
          expect(response.body).to include("scope=all")
        end

        it "is omitted without a server context (no this-server link)" do
          get notifications_path
          expect(response.body).not_to include("scope=server")
        end
      end
    end

    describe "PATCH /notifications/:id (dismiss)" do
      it "dismisses the notification and redirects with open: true" do
        patch notification_path(notif_a)
        expect(response).to redirect_to(notifications_path(server_id: nil, open: true))
        expect(notif_a.reload.dismissed_at).not_to be_nil
      end

      it "returns 404 for a notification on a non-authorized server" do
        patch notification_path(notif_other)
        expect(response).to have_http_status(:not_found)
      end

      it "preserves the server_id param in the redirect" do
        patch notification_path(notif_a, server_id: guild_a.id)
        expect(response).to redirect_to(notifications_path(server_id: guild_a.id, open: true))
      end
    end

    describe "POST /notifications/read (mark all read)" do
      it "marks all authorized notifications as read and redirects with open: true" do
        post notifications_read_path
        expect(response).to redirect_to(notifications_path(server_id: nil, open: true))
        expect(notif_a.reload.read_at).not_to be_nil
        expect(notif_b.reload.read_at).not_to be_nil
      end

      it "does not mark non-authorized notifications as read" do
        post notifications_read_path
        expect(notif_other.reload.read_at).to be_nil
      end

      context "scoped to the current server" do
        it "marks only that server's notifications as read" do
          post notifications_read_path(server_id: guild_a.id, scope: "server")
          expect(notif_a.reload.read_at).not_to be_nil
          expect(notif_b.reload.read_at).to be_nil
        end
      end

      context "with a server context but the all-servers scope" do
        it "marks every authorized server's notifications as read" do
          post notifications_read_path(server_id: guild_a.id, scope: "all")
          expect(notif_a.reload.read_at).not_to be_nil
          expect(notif_b.reload.read_at).not_to be_nil
        end
      end
    end
  end
end
