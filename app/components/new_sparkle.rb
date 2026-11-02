# frozen_string_literal: true

class Components::NewSparkle < Components::Base
  def view_template
    span(class: "flex-none text-accent-soft-fg") do
      span(aria_hidden: "true") { render Components::Icon.new("sparkle", weight: :fill, class: "size-3.5") }
      span(class: "sr-only") { t(".label") }
    end
  end
end
