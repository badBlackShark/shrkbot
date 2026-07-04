# frozen_string_literal: true

class Views::Servers::Reminders::Show < Views::Base
  def initialize(server_configuration:, user:)
    @config = server_configuration
    @user = user
  end

  def view_template
    render Components::PluginShell.new(user: @user, server_configuration: @config, active_key: :reminders) do
      render Components::ConfigPage.new(
        header: Components::ConfigPageHeader.new(
          icon: "bell-ringing",
          title: t(".title"),
          description: t(".description"),
          badge: t(".badge")
        ),
        server_configuration: @config,
        url: server_reminders_path(@config.discord_id)
      ) do
        render Components::Reminders::ConfigForm.new(server_configuration: @config)
      end
    end
  end
end
