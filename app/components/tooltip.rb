# frozen_string_literal: true

# Wraps a trigger and shows a small popover note on hover/focus. Fades in
# instantly (no native-title delay) and uses our surfaces and fonts. Reusable
# wherever a control needs a "why" on hover (e.g. a locked toggle, a
# disabled-with-reason select option).
class Components::Tooltip < Components::Base
  BUBBLE = "pointer-events-none absolute bottom-full right-0 z-20 mb-2 w-max max-w-64 rounded-md " \
    "border border-ink-200 bg-ink-0 px-3 py-2 text-xs font-medium leading-snug text-ink-700 shadow-lg " \
    "invisible opacity-0 transition-opacity motion-safe:duration-[120ms] " \
    "group-hover:visible group-hover:opacity-100 group-focus-within:visible group-focus-within:opacity-100"

  def initialize(text:)
    @text = text
  end

  def view_template(&block)
    span(class: "group relative inline-flex flex-none") do
      yield
      span(role: "tooltip", class: BUBBLE) { @text }
    end
  end
end
