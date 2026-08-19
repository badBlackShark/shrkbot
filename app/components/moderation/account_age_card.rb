# frozen_string_literal: true

class Components::Moderation::AccountAgeCard < Components::Base
  def initialize(new_account_age_days:)
    @new_account_age_days = new_account_age_days
  end

  def view_template
    render Components::Card.new do
      render Components::SettingRow.new(label: t(".label"), help: t(".help")) do
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
