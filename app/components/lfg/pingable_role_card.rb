# frozen_string_literal: true

class Components::Lfg::PingableRoleCard < Components::Base
  ICON_BUTTON = "flex size-8 flex-none items-center justify-center rounded-md text-text-muted transition-colors"

  def initialize(data:, context:)
    @data = data
    @context = context
  end

  def view_template
    details(
      open: @data.open,
      data: {pingable_role: true, controller: "dropdown", dropdown_dismiss_on_outside_value: "false"},
      class: "rounded-card border border-border-default bg-surface-card shadow-sm"
    ) do
      summary_row
      editor
    end
  end

  private

  def field(name)
    "lfg[pingable_roles][#{@data.index}][#{name}]"
  end

  def summary_row
    summary(
      class: "flex cursor-pointer list-none select-none items-center gap-2 px-4 py-3 [&::-webkit-details-marker]:hidden",
      data: {action: "click->dropdown#toggle"}
    ) do
      div(class: "min-w-0 flex-1") do
        span(class: "truncate text-sm font-semibold") { role_name }
        p(class: "mt-0.5 truncate text-xs text-text-muted") { subtitle }
      end
      delete_button
      render Components::Icon.new("caret-down", class: "dropdown-chevron size-4 flex-none text-text-muted")
    end
  end

  def delete_button
    render Components::Tooltip.new(text: t(".delete")) do
      button(
        type: "button",
        aria_label: t(".delete"),
        data: {action: "pingable-roles#remove"},
        class: "#{ICON_BUTTON} hover:bg-danger-soft hover:text-danger"
      ) { render Components::Icon.new("trash", class: "size-4") }
    end
  end

  def editor
    div(class: "dropdown-menu flex flex-col gap-5 border-t border-border-subtle p-5", data: {dropdown_target: "menu"}) do
      role_field
      required_field
      excluded_field
      channel_field
      min_days_field
    end
  end

  def role_field
    div do
      label(class: "mb-1.5 block text-sm font-semibold") { t(".role.label") }
      render Components::TomSelect.new(
        name: field(:role_id),
        options: @context.role_options,
        selected: @data.role_id,
        multiple: false,
        include_blank: true,
        controller_data: {tom_select_color_dots_value: true, tom_select_placeholder_value: t(".role.placeholder")}
      )
    end
  end

  def required_field
    render Components::Lfg::RoleGateField.new(
      name: "#{field(:required_role_ids)}[]",
      options: @context.role_options,
      selected: @data.required_role_ids,
      label: t(".required.label"),
      help: t(".required.help"),
      placeholder: t(".required.placeholder")
    )
  end

  def excluded_field
    render Components::Lfg::RoleGateField.new(
      name: "#{field(:excluded_role_ids)}[]",
      options: @context.role_options,
      selected: @data.excluded_role_ids,
      label: t(".excluded.label"),
      help: t(".excluded.help"),
      placeholder: t(".excluded.placeholder")
    )
  end

  def channel_field
    div do
      label(class: "mb-1.5 block text-sm font-semibold") { t(".channel.label") }
      render Components::ChannelSelect.new(
        name: "#{field(:allowed_channel_ids)}[]",
        options: @context.channels,
        selected: @data.allowed_channel_ids,
        placeholder: t(".channel.placeholder"),
        multiple: true
      )
      p(class: "mt-1.5 text-xs text-text-muted") { t(".channel.help") }
    end
  end

  def min_days_field
    render Components::Lfg::MinDaysField.new(
      name: field(:min_membership_days),
      value: @data.min_membership_days,
      label: t(".min_days.label"),
      help: t(".min_days.help"),
      placeholder: t(".min_days.placeholder"),
      unit: t(".min_days.unit")
    )
  end

  def role_name
    option = @context.role_options.find { |opt| opt.value.to_s == @data.role_id.to_s }
    option ? option.label : t(".unpicked")
  end

  def subtitle
    t(".summary", count: @data.required_role_ids.size + @data.excluded_role_ids.size)
  end
end
