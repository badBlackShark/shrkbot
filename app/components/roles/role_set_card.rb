# frozen_string_literal: true

class Components::Roles::RoleSetCard < Components::Base
  ICON_BUTTON = "flex size-8 flex-none items-center justify-center rounded-md text-text-muted transition-colors"

  def initialize(data:, context:)
    @data = data
    @context = context
  end

  def view_template
    details(
      open: @data.open,
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
    "roles[role_sets][#{@data.index}][#{name}]"
  end

  def hidden_fields
    input(type: "hidden", name: field(:id), value: @data.set_id, data: {role_set_id: true})
    input(type: "hidden", name: field(:_destroy), value: "0", data: {role_set_destroy: true})
  end

  def summary_row
    summary(
      class: "flex cursor-pointer list-none select-none items-center gap-2 px-4 py-3 [&::-webkit-details-marker]:hidden",
      data: {action: "click->dropdown#toggle"}
    ) do
      div(class: "min-w-0 flex-1") do
        div(class: "flex items-center gap-2") do
          span(class: "truncate text-sm font-semibold") { @data.name.presence || t(".unnamed") }
          render Components::Badge.new(variant: :brand, shape: :pill) { t(".mode.#{@data.selection_mode}") }
        end
        p(class: "mt-0.5 truncate text-xs text-text-muted") { subtitle }
      end
      repost_button
      delete_button
      render Components::Icon.new("caret-down", class: "dropdown-chevron size-4 flex-none text-text-muted")
    end
  end

  def delete_button
    render Components::Tooltip.new(text: t(".delete")) do
      button(
        type: "button",
        aria_label: t(".delete"),
        data: {action: "role-sets#remove"},
        class: "#{ICON_BUTTON} hover:bg-danger-soft hover:text-danger"
      ) { render Components::Icon.new("trash", class: "size-4") }
    end
  end

  def repost_button
    return if @data.repost_path.nil?

    render Components::Tooltip.new(text: t(".resync")) do
      button(
        type: "button",
        aria_label: t(".resync"),
        data: {
          action: "role-sets#repost",
          repost_url: @data.repost_path
        },
        class: "#{ICON_BUTTON} hover:bg-accent-soft hover:text-accent-soft-fg"
      ) { render Components::Icon.new("arrows-clockwise", class: "size-4") }
    end
  end

  def editor
    div(class: "dropdown-menu flex flex-col gap-5 border-t border-border-subtle p-5", data: {dropdown_target: "menu"}) do
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
          value: @data.name,
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
          value: @data.selection_mode,
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
        options: @context.channels,
        selected: @data.channel_override,
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
        options: @context.role_options,
        selected: @data.selected_role_ids,
        placeholder: t(".roles.placeholder")
      )
      unassignable_callout
    end
  end

  def unassignable_callout
    return unless @context.any_unassignable

    div(class: "mt-2.5") do
      render Components::Callout.new(variant: :warning) { t(".roles.unassignable") }
    end
  end

  def subtitle
    count = t(".roles.count", count: @data.selected_role_ids.size)
    label = channel_label
    label ? "##{label} · #{count}" : count
  end

  def channel_label
    @context.channels_by_id[(@data.channel_override || @context.default_channel_id).to_i]
  end

  def default_channel_label
    name = @context.channels_by_id[@context.default_channel_id.to_i]
    name ? "##{name}" : t(".channel.no_default")
  end
end
