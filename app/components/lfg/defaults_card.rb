# frozen_string_literal: true

class Components::Lfg::DefaultsCard < Components::Base
  def initialize(settings:, role_options:)
    @settings = settings
    @role_options = role_options
  end

  def view_template
    render Components::Card.new do
      h2(class: "text-sm font-semibold text-text-primary") { t(".title") }
      p(class: "mt-0.5 text-sm text-text-secondary") { t(".help") }
      div(class: "mt-4 flex flex-col gap-4") do
        required_field
        excluded_field
        min_days_field
      end
    end
  end

  private

  def required_field
    render Components::Lfg::RoleGateField.new(
      name: "lfg[default_required_role_ids][]",
      options: @role_options,
      selected: @settings.default_required_role_ids,
      label: t(".required.label"),
      help: t(".required.help"),
      placeholder: t(".required.placeholder")
    )
  end

  def excluded_field
    render Components::Lfg::RoleGateField.new(
      name: "lfg[default_excluded_role_ids][]",
      options: @role_options,
      selected: @settings.default_excluded_role_ids,
      label: t(".excluded.label"),
      help: t(".excluded.help"),
      placeholder: t(".excluded.placeholder")
    )
  end

  def min_days_field
    render Components::Lfg::MinDaysField.new(
      name: "lfg[default_min_membership_days]",
      value: @settings.default_min_membership_days,
      label: t(".min_days.label"),
      help: t(".min_days.help"),
      placeholder: t(".min_days.placeholder"),
      unit: t(".min_days.unit")
    )
  end
end
