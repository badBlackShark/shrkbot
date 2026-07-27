# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Plugin access enforcement", type: :request do
  include_context "discord auth"

  let(:guild) { Bot::Discord::Guild.new(id: 900_000_301, name: "Dev Refuge", owner: true, permissions: 0, icon: nil, member_count: 5) }
  let(:config) { ServerConfiguration.find_by(discord_id: guild.id) }
  let(:role_setting) { create(:role_setting, server_configuration: config) }
  let(:role_set) { create(:role_set, role_setting:) }

  before do
    create(:server_configuration, discord_id: guild.id, name: "Dev Refuge")
    allow(Bot::Discord::UserGuilds).to receive(:call).and_return([guild])
    post "/auth/discord/callback"
  end

  context "when the policy denies access to every plugin" do
    before do
      allow(PluginAccess).to receive(:new).and_return(instance_double(PluginAccess, manage?: false, visible?: true))
    end

    {
      roles: :server_roles_path,
      welcomes: :server_welcomes_path,
      logging: :server_logging_path,
      moderation: :server_moderation_path,
      spam_protection: :server_spam_protection_path,
      image_scanning: :server_image_scanning_path,
      lfg: :server_lfg_path,
      reminders: :server_reminders_path,
      twilight_struggle: :server_twilight_struggle_path
    }.each do |key, helper|
      it "redirects #{key} to the server dashboard with the locked alert" do
        get public_send(helper, guild.id)
        expect(response).to redirect_to(server_path(guild.id))
        expect(flash[:alert]).to eq(I18n.t("servers.plugin_locked"))
      end
    end

    it "redirects the plugin toggle action" do
      patch server_plugin_path(guild.id, :roles)
      expect(response).to redirect_to(server_path(guild.id))
    end

    it "redirects the role set repost action" do
      post server_role_set_repost_path(guild.id, role_set)
      expect(response).to redirect_to(server_path(guild.id))
    end
  end

  context "when the policy also denies visibility" do
    before do
      allow(PluginAccess).to receive(:new).and_return(instance_double(PluginAccess, manage?: false, visible?: false))
    end

    it "redirects with the unknown plugin alert" do
      get server_roles_path(guild.id)
      expect(response).to redirect_to(server_path(guild.id))
      expect(flash[:alert]).to eq(I18n.t("servers.unknown_plugin"))
    end
  end
end
