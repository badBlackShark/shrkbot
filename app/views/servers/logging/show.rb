# frozen_string_literal: true

class Views::Servers::Logging::Show < Views::Base
  def initialize(server_configuration:, user:, enabled:)
    @config = server_configuration
    @user = user
    @enabled = enabled
  end

  def view_template
    render Components::PluginShell.new(user: @user, server_configuration: @config, active_key: :logging) do
      render Components::ConfigPage.new(
        header: Components::ConfigPageHeader.new(
          icon: "scroll",
          title: t(".title"),
          description: t(".description")
        ),
        server_configuration: @config,
        url: server_logging_path(@config.discord_id),
        gate: {
          field: "logging[enabled]",
          enabled: @enabled,
          message: t(".gate_message")
        },
        channel_lost: @enabled && @config.logging_setting.channel_id.nil?
      ) do
        render Components::Logging::ConfigForm.new(server_configuration: @config)
      end
    end
  end
end
