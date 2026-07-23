# frozen_string_literal: true

class Components::Lfg::DefaultsCard < Components::Base
  def initialize(settings:, role_options:, channels:)
    @settings = settings
    @role_options = role_options
    @channels = channels
  end

  def view_template
    render Components::Card.new(padding: :none, class: "overflow-hidden") do
      details(data: {controller: "disclosure", disclosure_key_value: "lfg-defaults"}) do
        summary_row
        body
      end
    end
  end

  private

  def summary_row
    summary(
      class: "flex cursor-pointer list-none select-none items-center gap-3 p-5 [&::-webkit-details-marker]:hidden",
      data: {action: "click->disclosure#toggle"}
    ) do
      div(class: "min-w-0 flex-1") do
        p(class: "text-sm font-semibold text-text-primary") { t(".title") }
        p(class: "mt-0.5 text-xs text-text-muted") { t(".subtitle") }
      end
      render Components::Icon.new("caret-down", class: "dropdown-chevron size-4 flex-none text-text-muted")
    end
  end

  def body
    div(class: "flex flex-col gap-5 border-t border-border-subtle p-5") do
      p(class: "text-sm text-text-secondary") { t(".help") }
      required_field
      excluded_field
      min_days_field
      render Components::Lfg::ChannelsField.new(channels: @channels, selected: @settings.allowed_channel_ids)
      cooldown_field
      lifetime_field
    end
  end

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

  def cooldown_field
    render Components::Lfg::NumberSettingField.new(
      name: "lfg[cooldown_seconds]",
      value: @settings.cooldown_seconds,
      min: 0,
      max: 86_400,
      default: t(".cooldown.default"),
      unit: t(".cooldown.unit"),
      label: t(".cooldown.label"),
      help: t(".cooldown.help")
    )
  end

  def lifetime_field
    render Components::Lfg::NumberSettingField.new(
      name: "lfg[post_lifetime_minutes]",
      value: @settings.post_lifetime_minutes,
      min: 5,
      max: 10_080,
      default: t(".lifetime.default"),
      unit: t(".lifetime.unit"),
      label: t(".lifetime.label"),
      help: t(".lifetime.help")
    )
  end
end
