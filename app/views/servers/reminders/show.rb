# frozen_string_literal: true

class Views::Servers::Reminders::Show < Views::Base
  def initialize(server_configuration:, user:)
    @config = server_configuration
    @user = user
  end

  def view_template
    render Components::AppShell.new(
      user: @user,
      sidebar: Components::PluginSidebar.new(server_configuration: @config, active_key: :reminders)
    ) do
      render Components::ConfigPage.new(
        icon: "bell-ringing",
        title: t(".title"),
        description: t(".description"),
        dashboard_path: server_path(@config.discord_id),
        dashboard_label: @config.name,
        url: server_reminders_path(@config.discord_id),
        badge: t(".badge")
      ) do
        render Components::Reminders::ConfigForm.new(server_configuration: @config)
      end
    end
  end
end
