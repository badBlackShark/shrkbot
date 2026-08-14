# frozen_string_literal: true

class PreviewsController < ApplicationController
  def show
    render Views::Servers::Show.new(
      server: PreviewData.demo_guild,
      server_configuration:,
      plugins: PluginStatus.rows(server_configuration, access: plugin_access),
      user: current_user,
      servers: [PreviewData.demo_guild],
      plugin_counts: PluginActivation.enabled_counts_for([server_configuration.discord_id])
    )
  end

  def destroy
    session.delete(:user_id) if session.delete(:preview_identity)
    redirect_to root_path
  end

  private

  def server_configuration
    @server_configuration ||= ServerConfiguration.previews.find_by!(discord_id: PreviewData.guild[:discord_id])
  end

  def plugin_access
    @plugin_access ||= PluginAccess.new(user: current_user, server_configuration:, manages_server: true)
  end
end
