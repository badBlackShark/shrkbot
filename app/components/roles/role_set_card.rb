# frozen_string_literal: true

class Components::Roles::RoleSetCard < Components::Base
  ICON_BUTTON = "flex size-8 flex-none items-center justify-center rounded-md text-text-muted transition-colors"

  def initialize(
    index:,
    channels:,
    role_options:,
    channels_by_id:,
    default_channel_id:,
    any_unassignable:,
    set_id: nil,
    name: "",
    selection_mode: "single",
    channel_override: nil,
    selected_role_ids: [],
    open: false
  )
    @index = index
    @channels = channels
    @role_options = role_options
    @channels_by_id = channels_by_id
    @default_channel_id = default_channel_id
    @any_unassignable = any_unassignable
    @set_id = set_id
    @name = name
    @selection_mode = selection_mode
    @channel_override = channel_override
    @selected_role_ids = selected_role_ids
    @open = open
  end

  def view_template
    details(
      open: @open,
      data: {role_set: true, controller: "dropdown", dropdown_dismiss_on_outside_value: "false"},
      class: "rounded-card border border-border-default bg-surface-card shadow-sm"
    ) do
      hidden_fields
      summary_row
      editor
    end
  end

  private

  def field(name)
    "roles[role_sets][#{@index}][#{name}]"
  end

  def hidden_fields
    input(type: "hidden", name: field(:id), value: @set_id, data: {role_set_id: true})
    input(type: "hidden", name: field(:_destroy), value: "0", data: {role_set_destroy: true})
  end

  def summary_row
    summary(
      class: "flex cursor-pointer list-none select-none items-center gap-2 px-4 py-3 [&::-webkit-details-marker]:hidden",
      data: {action: "click->dropdown#toggle"}
    ) do
      div(class: "min-w-0 flex-1") do
        div(class: "flex items-center gap-2") do
          span(class: "truncate text-sm font-semibold") { @name.presence || t(".unnamed") }
          render Components::Badge.new(variant: :brand, shape: :pill) { t(".mode.#{@selection_mode}") }
        end
        p(class: "mt-0.5 truncate text-xs text-text-muted") { subtitle }
      end
      delete_button
      render Components::Icon.new("caret-down", class: "dropdown-chevron size-4 flex-none text-text-muted")
    end
  end

  def delete_button
    button(
      type: "button",
      title: t(".delete"),
      aria_label: t(".delete"),
      data: {action: "role-sets#remove"},
      class: "#{ICON_BUTTON} flex-none hover:bg-danger-soft hover:text-danger"
    ) { render Components::Icon.new("trash", class: "size-4") }
  end

  def editor
    div(class: "dropdown-menu grid gap-5 border-t border-border-subtle p-5", data: {dropdown_target: "menu"}) do
      top_fields
      channel_override_field
      roles_field
    end
  end

  def top_fields
    div(class: "grid gap-5 sm:grid-cols-2") do
      div do
        label(class: "mb-1.5 block text-sm font-semibold") { t(".name.label") }
        input(
          type: "text",
          name: field(:name),
          value: @name,
          required: true,
          data: {role_set_name: true},
          class: "h-10 w-full rounded-control border-[1.5px] border-border-strong bg-surface-card px-3 text-sm " \
            "focus:border-accent focus:outline-none focus:ring-3 focus:ring-[var(--focus-ring)]"
        )
      end
      div do
        label(class: "mb-1.5 block text-sm font-semibold") { t(".selection.label") }
        render Components::SegmentedControl.new(
          name: field(:selection_mode),
          value: @selection_mode,
          options: [
            {value: "single", label: t(".mode.single")},
            {value: "multi", label: t(".mode.multi")}
          ]
        )
      end
    end
  end

  def channel_override_field
    div do
      label(class: "mb-1.5 block text-sm font-semibold") do
        plain t(".channel.label")
        span(class: "font-normal text-text-muted") { " #{t(".channel.optional")}" }
      end
      render Components::ChannelSelect.new(
        name: field(:channel_override),
        options: @channels,
        selected: @channel_override,
        placeholder: t(".channel.placeholder", channel: default_channel_label),
        include_blank: true
      )
    end
  end

  def roles_field
    div do
      label(class: "mb-1.5 block text-sm font-semibold") { t(".roles.label") }
      render Components::RoleSelect.new(
        name: "#{field(:role_ids)}[]",
        options: @role_options,
        selected: @selected_role_ids,
        placeholder: t(".roles.placeholder")
      )
      unassignable_callout
    end
  end

  def unassignable_callout
    return unless @any_unassignable

    div(class: "mt-2.5") do
      render Components::Callout.new(variant: :warning) { t(".roles.unassignable") }
    end
  end

  def subtitle
    count = t(".roles.count", count: @selected_role_ids.size)
    label = channel_label
    label ? "##{label} · #{count}" : count
  end

  def channel_label
    @channels_by_id[(@channel_override || @default_channel_id).to_i]
  end

  def default_channel_label
    name = @channels_by_id[@default_channel_id.to_i]
    name ? "##{name}" : t(".channel.no_default")
  end
end
