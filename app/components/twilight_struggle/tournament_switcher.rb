# frozen_string_literal: true

class Components::TwilightStruggle::TournamentSwitcher < Components::Base
  def initialize(current:, destinations:)
    @current = current
    @destinations = destinations
  end

  def view_template
    return current_only if others.empty?

    details(class: "group relative", data: {controller: "dropdown"}) do
      summary(
        data: {action: "click->dropdown#toggle"},
        class: "flex h-8 cursor-pointer list-none items-center gap-1.5 rounded-control border border-border-strong " \
          "bg-surface-card px-3 text-sm font-semibold transition-colors hover:bg-surface-sunken " \
          "[&::-webkit-details-marker]:hidden"
      ) do
        span(class: "whitespace-nowrap") { @current.tournament.name }
        render Components::Icon.new("caret-down", class: "dropdown-chevron size-4 text-text-muted")
      end
      menu
    end
  end

  private

  def current_only
    render Components::Badge.new(variant: :copper) { @current.tournament.name }
  end

  def menu
    div(
      data: {dropdown_target: "menu"},
      class: "dropdown-menu absolute right-0 top-10 z-40 w-72 overflow-hidden rounded-lg border " \
        "border-border-default bg-surface-card py-1.5 shadow-lg"
    ) do
      p(class: "px-3 pb-1 pt-0.5 text-[10px] font-semibold uppercase tracking-widest text-eyebrow") { t(".label") }
      others.each { |destination| row(destination) }
    end
  end

  def row(destination)
    a(
      href: edit_server_twilight_struggle_destination_path(destination.server_configuration.discord_id, destination),
      class: "flex flex-col gap-0.5 px-3 py-2 text-sm transition-colors hover:bg-surface-sunken"
    ) do
      span(class: "font-medium") { destination.tournament.name }
      parent_line(destination)
    end
  end

  def parent_line(destination)
    return unless destination.tournament.parent

    span(class: "text-xs text-text-secondary") { t(".under", parent: destination.tournament.parent.name) }
  end

  def others
    @others ||= @destinations.reject { |destination| destination.id == @current.id }
  end
end
