# frozen_string_literal: true

class Views::Servers::TwilightStruggle::Destinations::Edit < Views::Base
  def initialize(user:, destination:, destinations:, enabled:)
    @user = user
    @destination = destination
    @destinations = destinations
    @enabled = enabled
  end

  def view_template
    render Components::PluginShell.new(user: @user, server_configuration:, active_key: ::TwilightStruggle::PLUGIN_KEY) do
      render Components::ConfigPage.new(
        header:,
        server_configuration:,
        url: server_twilight_struggle_destination_path(server_configuration.discord_id, @destination),
        toggle: {field: "destination[enabled]", enabled: @enabled},
        gate: {type: :enable, message: t(".gate_message")},
        header_aside: switcher,
        parent_crumb: {label: t(".tournaments"), href: server_twilight_struggle_path(server_configuration.discord_id)}
      ) do
        render Components::TwilightStruggle::ConfigForm.new(destination: @destination)
      end
    end
  end

  private

  def header
    Components::ConfigPageHeader.new(icon: "trophy", title: t(".title"), description: t(".description"))
  end

  def switcher
    Components::TwilightStruggle::TournamentSwitcher.new(current: @destination, destinations: @destinations)
  end

  def server_configuration
    @destination.server_configuration
  end
end
