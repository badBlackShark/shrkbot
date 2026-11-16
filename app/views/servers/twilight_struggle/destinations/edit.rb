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
        url: server_twilight_struggle_destination_path(server_configuration.discord_id, tournament),
        toggle: {
          field: "destination[subscribed]",
          enabled: @destination.active? && @destination.persisted?,
          label: t(".subscribe", tournament: tournament.name)
        },
        prerequisites:,
        parent_crumb:
      ) do
        render Components::TwilightStruggle::ConfigForm.new(destination: @destination)
      end
    end
  end

  private

  def header
    Components::ConfigPageHeader.new(
      icon: "trophy",
      title: tournament.name,
      aside: switcher
    )
  end

  def parent_crumb
    {
      label: PluginCatalog.find(::TwilightStruggle::PLUGIN_KEY).name,
      href: server_twilight_struggle_path(server_configuration.discord_id)
    }
  end

  def tournament
    @destination.tournament
  end

  def prerequisites
    return if @enabled

    Components::PrerequisiteSteps.new(
      icon: "trophy",
      title: t(".prerequisites.title"),
      steps: [
        Components::PrerequisiteSteps::Step.new(
          message: t(".prerequisites.message"),
          cta_label: t(".prerequisites.cta"),
          cta_href: server_twilight_struggle_path(server_configuration.discord_id)
        )
      ]
    )
  end

  def switcher
    Components::TwilightStruggle::TournamentSwitcher.new(current: @destination, destinations: @destinations)
  end

  def server_configuration
    @destination.server_configuration
  end
end
