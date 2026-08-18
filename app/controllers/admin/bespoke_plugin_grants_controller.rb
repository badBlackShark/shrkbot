# frozen_string_literal: true

class Admin::BespokePluginGrantsController < ApplicationController
  include RequiresOwner

  def index
    render Views::Admin::BespokePluginGrants::Index.new(
      user: current_user,
      definitions: PluginCatalog.bespoke,
      grants: BespokePluginGrant.grouped_by_plugin_key,
      servers: ServerConfiguration.real.order(:name)
    )
  end

  def create
    server_configuration = ServerConfiguration.find_by(id: params[:server_configuration_id])
    return head :not_found unless server_configuration && bespoke_key?

    Ops::ServerConfiguration::BespokePluginGrant::Create.call(
      server_configuration:,
      plugin_key: params[:plugin_key]
    )
    redirect_to admin_bespoke_plugin_grants_path, notice: t("admin.bespoke_plugin_grants.granted")
  end

  def destroy
    grant = BespokePluginGrant.find_by(id: params[:id])
    return head :not_found unless grant

    Ops::ServerConfiguration::BespokePluginGrant::Destroy.call(bespoke_plugin_grant: grant)
    redirect_to admin_bespoke_plugin_grants_path, notice: t("admin.bespoke_plugin_grants.revoked")
  end

  private

  def bespoke_key?
    PluginCatalog.bespoke.any? { |definition| definition.key.to_s == params[:plugin_key] }
  end
end
