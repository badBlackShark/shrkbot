# frozen_string_literal: true

class Views::Servers::Roles::Show < Views::Base
  def initialize(server_configuration:, user:, enabled:)
    @config = server_configuration
    @user = user
    @enabled = enabled
  end

  def view_template
    render Components::AppShell.new(
      user: @user,
      sidebar: Components::PluginSidebar.new(server_configuration: @config, active_key: :roles)
    ) do
      render Components::ConfigPage.new(
        icon: "users-three",
        title: t(".title"),
        description: t(".description"),
        dashboard_path: server_path(@config.discord_id),
        url: server_roles_path(@config.discord_id),
        gate: {
          field: "roles[enabled]",
          enabled: @enabled,
          message: t(".gate_message")
        }
      ) do
        render Components::Roles::ConfigForm.new(server_configuration: @config)
      end
    end
  end
end
