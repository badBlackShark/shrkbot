# frozen_string_literal: true

class Components::TwilightStruggle::ArchiveFilter < Components::Base
  ACTIVE = "border-accent bg-accent-soft text-accent-soft-fg font-semibold"
  INACTIVE = "border-border-default text-text-secondary font-medium hover:bg-surface-sunken"
  BASE = "inline-flex h-8 items-center rounded-control border-[1.5px] px-3 text-xs transition-colors"

  def initialize(server_configuration:, archived:)
    @server_configuration = server_configuration
    @archived = archived
  end

  def view_template
    div(class: "flex gap-2") do
      tab(t(".active"), server_twilight_struggle_path(@server_configuration.discord_id), !@archived)
      tab(t(".archived"), server_twilight_struggle_path(@server_configuration.discord_id, archived: 1), @archived)
    end
  end

  private

  def tab(label, href, current)
    a(href:, aria_current: current ? "page" : nil, class: "#{BASE} #{current ? ACTIVE : INACTIVE}") { label }
  end
end
