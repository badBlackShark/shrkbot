# frozen_string_literal: true

class Components::Moderation::AccountAgeCard < Components::Base
  def initialize(new_account_age_days:)
    @new_account_age_days = new_account_age_days
  end

  def view_template
    render Components::Card.new do
      div(class: "flex items-center justify-between gap-4") do
        div(class: "max-w-md") do
          label(class: "text-sm font-semibold") { t(".label") }
          p(class: "mt-1.5 text-xs text-text-muted") { t(".help") }
        end
        render Components::NumberStepper.new(
          name: "moderation[new_account_age_days]",
          value: @new_account_age_days,
          min: 1,
          max: 365,
          default: 30,
          unit: t(".days_unit")
        )
      end
    end
  end
end
