# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Preview", type: :request do
  include_context "discord auth"

  let!(:plugins) do
    Plugin.insert_all(
      PluginCatalog.all.map do |definition|
        {key: definition.key.to_s, name: definition.name, description: definition.description, created_at: Time.current, updated_at: Time.current}
      end
    )
  end

  let!(:preview_configuration) { Ops::ServerConfiguration::Previews::Create.call.value }

  describe "GET /preview" do
    subject(:get_preview) { get preview_path }

    context "when signed out" do
      it "renders the preview dashboard" do
        get_preview
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("The Reef")
      end

      it "creates the demo user identity" do
        expect { get_preview }.to change(User, :count).by(1)
      end

      it "signs the visitor in as the demo user" do
        get_preview
        expect(session[:user_id]).to eq(User.find_by(discord_id: PreviewData.user[:discord_id]).id)
      end

      it "flags the identity as preview-created" do
        get_preview
        expect(session[:preview_identity]).to be(true)
      end
    end

    context "when a real user is signed in" do
      before { post "/auth/discord/callback" }

      it "renders the preview dashboard" do
        get_preview
        expect(response).to have_http_status(:ok)
      end

      it "leaves the signed-in user's session id unchanged" do
        expect { get_preview }.not_to change { session[:user_id] }
      end

      it "does not create a demo user" do
        expect { get_preview }.not_to change(User, :count)
      end

      it "does not flag the identity as preview-created" do
        get_preview
        expect(session[:preview_identity]).to be_nil
      end
    end
  end

  describe "GET /preview/roles" do
    before { get preview_path }

    it "renders the real roles config page against the preview guild" do
      get preview_roles_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Roles")
      expect(response.body).to include("Pronouns")
    end

    it "never links or posts back to the real server routes" do
      get preview_roles_path
      expect(response.body).not_to match(%r{(href|action)="/servers/})
    end
  end

  describe "GET /preview/welcomes" do
    before { get preview_path }

    it "renders the real welcomes config page against the preview guild" do
      get preview_welcomes_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Welcome to The Reef")
    end

    it "never links or posts back to the real server routes" do
      get preview_welcomes_path
      expect(response.body).not_to match(%r{(href|action)="/servers/})
    end
  end

  describe "a deep link into a preview page" do
    subject(:deep_link) { get preview_welcomes_path }

    context "when the visitor is signed out and has never opened the dashboard" do
      it "renders the page instead of bouncing to the login screen" do
        deep_link

        expect(response).to have_http_status(:ok)
      end

      it "establishes the demo identity on the way in" do
        expect { deep_link }.to change(User, :count).by(1)
      end
    end
  end

  describe "the Discord seam" do
    before do
      allow(Bot::Discord::UserGuilds).to receive(:call)
    end

    it "is never called for a preview visit" do
      get preview_path
      get preview_welcomes_path
      expect(Bot::Discord::UserGuilds).not_to have_received(:call)
    end

    it "does not write authorized or managed server ids into the session" do
      get preview_path
      get preview_welcomes_path
      expect(session[:authorized_server_ids]).to be_nil
      expect(session[:managed_server_ids]).to be_nil
    end
  end

  describe "PATCH /preview/roles" do
    before { get preview_path }

    it "blocks the write and leaves the configuration unchanged" do
      expect {
        patch preview_roles_path, params: {roles: {channel_id: "", enabled: "1", role_sets: {}}}
      }.not_to change { preview_configuration.reload.role_setting.channel_id }
    end

    it "redirects with an alert instead of running the action" do
      patch preview_roles_path, params: {roles: {channel_id: "", enabled: "1", role_sets: {}}}
      expect(response).to redirect_to(preview_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe "reaching the preview guild through the real server routes" do
    subject(:sneak) { patch server_plugin_path(preview_configuration.discord_id, :roles), params: {enabled: "0"} }

    before do
      get preview_path
      allow(Bot::ConfigBus).to receive(:publish)
    end

    it "does not toggle the plugin" do
      expect { sneak }.not_to change {
        preview_configuration.plugin_activations.joins(:plugin).find_by(plugins: {key: "roles"}).enabled
      }
    end

    it "never asks the bot to sync commands for a guild it is not in" do
      sneak

      expect(Bot::ConfigBus).not_to have_received(:publish)
    end
  end

  describe "leaving preview by navigating away" do
    subject(:real_dashboard) { get servers_path }

    before do
      post "/auth/discord/callback"
      get preview_path
    end

    it "shows a signed-in user their own servers again, with no exit step" do
      real_dashboard

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("The Reef")
    end
  end

  describe "DELETE /preview" do
    context "when the demo identity was created for a logged-out visitor" do
      before { get preview_path }

      it "signs the demo identity back out" do
        delete preview_path

        expect(session[:user_id]).to be_nil
        expect(session[:preview_identity]).to be_nil
      end

      it "redirects to the root path" do
        delete preview_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "when a real user is signed in" do
      before do
        post "/auth/discord/callback"
        get preview_path
      end

      it "leaves the real user signed in" do
        expect { delete preview_path }.not_to change { session[:user_id] }
      end
    end
  end
end
