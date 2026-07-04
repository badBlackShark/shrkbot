# frozen_string_literal: true

class Components::PluginShell < Components::Base
  def initialize(user:, server_configuration:, active_key:)
    @user = user
    @server_configuration = server_configuration
    @active_key = active_key
  end

  def view_template(&block)
    render Components::AppShell.new(
      user: @user,
      current_server_id: @server_configuration.discord_id,
      sidebar: Components::PluginSidebar.new(server_configuration: @server_configuration, active_key: @active_key)
    ), &block
  end
end
