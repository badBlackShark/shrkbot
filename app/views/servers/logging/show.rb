# frozen_string_literal: true

class Views::Servers::Logging::Show < Views::Base
  def initialize(server_configuration:, user:, enabled:)
    @config = server_configuration
    @user = user
    @enabled = enabled
  end

  def view_template
    render Components::AppShell.new(user: @user) do
      render Components::ConfigPage.new(
        icon: "scroll",
        title: t(".title"),
        description: t(".description"),
        dashboard_path: server_path(@config.discord_id),
        gate: {
          url: server_logging_path(@config.discord_id),
          field: "logging[enabled]",
          enabled: @enabled,
          message: t(".gate_message")
        }
      ) do
        render Components::Logging::ConfigForm.new(server_configuration: @config)
      end
    end
  end
end
