# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin bespoke plugin grants", type: :request do
  include_context "discord auth"

  include_context "with a bespoke plugin definition"

  let(:server) { create(:server_configuration, name: "Test Guild") }

  before do
    allow(Bot::ConfigBus).to receive(:sync_commands)
  end

  context "when signed out" do
    it "redirects to the sign-in page" do
      get admin_bespoke_plugin_grants_path
      expect(response).to redirect_to(root_path)
    end
  end

  context "when signed in as a non-owner" do
    before do
      allow(Bot::Config).to receive(:owner_id).and_return("99999")
      post "/auth/discord/callback"
    end

    describe "GET /admin/bespoke_plugin_grants" do
      it "redirects to the server picker with an alert" do
        get admin_bespoke_plugin_grants_path
        expect(response).to redirect_to(servers_path)
        expect(flash[:alert]).to be_present
      end
    end

    describe "POST /admin/bespoke_plugin_grants" do
      it "redirects without granting" do
        post admin_bespoke_plugin_grants_path, params: {plugin_key: "bespoke_thing", server_configuration_id: server.id}
        expect(response).to redirect_to(servers_path)
        expect(BespokePluginGrant.count).to eq(0)
      end
    end

    describe "DELETE /admin/bespoke_plugin_grants/:id" do
      let!(:grant) { create(:bespoke_plugin_grant, server_configuration: server, plugin_key: "bespoke_thing") }

      it "redirects without revoking" do
        delete admin_bespoke_plugin_grant_path(grant)
        expect(response).to redirect_to(servers_path)
        expect(BespokePluginGrant.exists?(grant.id)).to be(true)
      end
    end
  end

  context "when signed in as the owner" do
    before do
      allow(Bot::Config).to receive(:owner_id).and_return("12345")
      post "/auth/discord/callback"
    end

    describe "GET /admin/bespoke_plugin_grants" do
      subject(:index_page) { get admin_bespoke_plugin_grants_path }

      before { server }

      it "lists the bespoke plugin and offers the ungranted server" do
        index_page
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Bespoke Thing")
        expect(response.body).to include("Test Guild")
        expect(response.body).to include(I18n.t("components.admin.bespoke_plugin_card.none"))
      end

      context "when the only server is already granted" do
        let!(:grant) { create(:bespoke_plugin_grant, server_configuration: server, plugin_key: "bespoke_thing") }

        it "lists the grant and says there is nothing left to grant" do
          index_page
          expect(response.body).to include(I18n.t("components.admin.bespoke_plugin_card.all_granted"))
          expect(response.body).to include(I18n.t("components.admin.bespoke_plugin_grant_row.revoke"))
        end
      end

      context "when the granted server has no name synced yet" do
        let(:server) { create(:server_configuration, name: nil) }
        let!(:grant) { create(:bespoke_plugin_grant, server_configuration: server, plugin_key: "bespoke_thing") }

        it "falls back to the guild id" do
          index_page
          expect(response.body).to include(server.discord_id.to_s)
        end
      end

      context "when no bespoke plugins exist" do
        let(:catalog_definitions) { PluginCatalog::DEFINITIONS.reject(&:bespoke) }

        it "renders the empty state" do
          index_page
          expect(response.body).to include(I18n.t("views.admin.bespoke_plugin_grants.index.empty_title"))
        end
      end
    end

    describe "POST /admin/bespoke_plugin_grants" do
      subject(:grant_plugin) do
        post admin_bespoke_plugin_grants_path, params: {plugin_key:, server_configuration_id:}
      end

      let(:plugin_key) { "bespoke_thing" }
      let(:server_configuration_id) { server.id }

      it "grants the plugin to the server" do
        grant_plugin
        expect(response).to redirect_to(admin_bespoke_plugin_grants_path)
        expect(BespokePluginGrant.where(server_configuration: server, plugin_key: "bespoke_thing")).to exist
      end

      context "with a plugin key that is not bespoke" do
        let(:plugin_key) { "roles" }

        it "returns not found and grants nothing" do
          grant_plugin
          expect(response).to have_http_status(:not_found)
          expect(BespokePluginGrant.count).to eq(0)
        end
      end

      context "with an unknown server" do
        let(:server_configuration_id) { "srv_missing" }

        it "returns not found" do
          grant_plugin
          expect(response).to have_http_status(:not_found)
          expect(BespokePluginGrant.count).to eq(0)
        end
      end
    end

    describe "DELETE /admin/bespoke_plugin_grants/:id" do
      subject(:revoke) { delete admin_bespoke_plugin_grant_path(id) }

      let!(:grant) { create(:bespoke_plugin_grant, server_configuration: server, plugin_key: "bespoke_thing") }
      let(:id) { grant.id }

      it "revokes the grant" do
        revoke
        expect(response).to redirect_to(admin_bespoke_plugin_grants_path)
        expect(BespokePluginGrant.exists?(grant.id)).to be(false)
      end

      context "with an unknown grant" do
        let(:id) { "bpg_missing" }

        it "returns not found" do
          revoke
          expect(response).to have_http_status(:not_found)
          expect(BespokePluginGrant.exists?(grant.id)).to be(true)
        end
      end
    end
  end
end
