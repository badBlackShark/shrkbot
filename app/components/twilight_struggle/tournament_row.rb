# frozen_string_literal: true

class Components::TwilightStruggle::TournamentRow < Components::Base
  def initialize(tournament:, destination:, server_configuration:, channel_labels:)
    @tournament = tournament
    @destination = destination
    @server_configuration = server_configuration
    @channel_labels = channel_labels
  end

  def view_template
    render Components::Card.new(class: "flex flex-wrap items-center gap-4") do
      identity
      actions
    end
  end

  private

  def identity
    div(class: "min-w-0 flex-1") do
      div(class: "flex flex-wrap items-center gap-2") do
        p(class: "text-sm font-semibold") { @tournament.name }
        badges
      end
      parent_line
    end
  end

  def badges
    render Components::Badge.new(variant: :neutral) { t(".friendly") } if @tournament.friendly?
    render Components::Badge.new(variant: :neutral) { t(".closed") } if @tournament.closed_upstream?
    render Components::Badge.new(variant: :warning) { t(".archived") } if @destination&.manually_archived?
  end

  def parent_line
    return unless @tournament.parent

    p(class: "mt-0.5 text-xs text-text-secondary") { t(".under", parent: @tournament.parent.name) }
  end

  def actions
    if @destination
      render Components::TwilightStruggle::DestinationActions.new(
        destination: @destination,
        channel_label: @channel_labels[@destination.discord_channel_id]
      )
    else
      render Components::TwilightStruggle::SubscribeButton.new(tournament: @tournament, server_configuration: @server_configuration)
    end
  end
end
