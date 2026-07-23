# frozen_string_literal: true

class Components::Lfg::LifetimeCard < Components::Base
  def initialize(value:)
    @value = value
  end

  def view_template
    render Components::Card.new do
      label(class: "block text-sm font-semibold") { t(".label") }
      p(class: "mb-2 mt-0.5 text-sm text-text-secondary") { t(".help") }
      render Components::NumberStepper.new(
        name: "lfg[post_lifetime_minutes]",
        value: @value,
        min: 5,
        max: 10_080,
        default: t(".default"),
        unit: t(".unit")
      )
    end
  end
end
