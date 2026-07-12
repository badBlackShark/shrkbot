# frozen_string_literal: true

class Components::Tooltip < Components::Base
  PLACEMENTS = {
    up: "bottom-full mb-2",
    down: "top-full mt-2"
  }.freeze

  BUBBLE = "pointer-events-none absolute right-0 z-20 w-max max-w-64 rounded-md " \
    "border border-border-default bg-surface-card px-3 py-2 text-xs font-medium leading-snug text-text-secondary shadow-lg " \
    "invisible opacity-0 transition-opacity motion-safe:duration-[120ms] " \
    "group-hover:visible group-hover:opacity-100 group-focus-within:visible group-focus-within:opacity-100"

  def initialize(text:, placement: :up)
    @text = text
    @placement = PLACEMENTS.fetch(placement)
  end

  def view_template(&block)
    span(class: "group relative inline-flex flex-none") do
      yield
      span(role: "tooltip", class: "#{BUBBLE} #{@placement}") { @text }
    end
  end
end
