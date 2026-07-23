# frozen_string_literal: true

class Views::Servers::Lfg::Show < Views::Base
  def initialize(server_configuration:, user:, enabled:)
    @config = server_configuration
    @user = user
    @enabled = enabled
  end

  def view_template
    render Components::PluginShell.new(user: @user, server_configuration: @config, active_key: :lfg) do
      render Components::ConfigPage.new(
        header: Components::ConfigPageHeader.new(
          icon: "game-controller",
          title: t(".title"),
          description: t(".description")
        ),
        server_configuration: @config,
        url: server_lfg_path(@config.discord_id),
        toggle: {field: "lfg[enabled]", enabled: @enabled},
        gate: {type: :enable, message: t(".gate_message")}
      ) do
        render Components::Lfg::ConfigForm.new(server_configuration: @config)
      end
    end
  end
end
