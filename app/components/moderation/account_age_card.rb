# frozen_string_literal: true

class Components::Moderation::AccountAgeCard < Components::Base
  def initialize(new_account_age_days:)
    @new_account_age_days = new_account_age_days
  end

  def view_template
    render Components::Card.new do
      render Components::InlineField.new(label: t(".label")) do
        render Components::NumberStepper.new(
          name: "moderation[new_account_age_days]",
          value: @new_account_age_days,
          min: 1,
          max: 365,
          default: ::Moderation::Settings.column_defaults.fetch("new_account_age_days"),
          unit: t(".days_unit")
        )
      end
      render Components::FieldHelp.new { t(".help") }
    end
  end
end
