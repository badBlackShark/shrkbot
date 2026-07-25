# frozen_string_literal: true

class Views::TwilightStruggle::Tournaments::Edit < Views::Base
  def initialize(user:, tournament:, enabled:)
    @user = user
    @tournament = tournament
    @enabled = enabled
  end

  def view_template
    render Components::PluginShell.new(user: @user, server_configuration: server_configuration, active_key: ::TwilightStruggle::PLUGIN_KEY) do
      render Components::ConfigPage.new(
        header: header,
        server_configuration: server_configuration,
        url: twilight_struggle_tournament_path(@tournament),
        toggle: {field: "tournament[enabled]", enabled: @enabled},
        gate: {type: :enable, message: t(".gate_message")},
        parent_crumb: {label: t(".tournaments"), href: twilight_struggle_tournaments_path}
      ) do
        render Components::TwilightStruggle::ConfigForm.new(tournament: @tournament)
      end
    end
  end

  private

  def header
    Components::ConfigPageHeader.new(
      icon: "trophy",
      title: t(".title"),
      badge: @tournament.name,
      description: t(".description")
    )
  end

  def server_configuration
    @tournament.server_configuration
  end
end
