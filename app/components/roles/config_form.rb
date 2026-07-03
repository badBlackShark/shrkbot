# frozen_string_literal: true

class Components::Roles::ConfigForm < Components::Base
  def initialize(server_configuration:)
    @config = server_configuration
    @setting = server_configuration.role_setting
  end

  def view_template
    div(id: "roles-config", class: "flex flex-col gap-5", data: {controller: "role-sets"}) do
      default_channel_card
      role_sets_section
    end
  end

  private

  def default_channel_card
    render Components::Card.new do
      label(class: "block text-sm font-semibold") { t(".channel.label") }
      p(class: "mb-2 mt-0.5 text-sm text-text-secondary") { t(".channel.help") }
      if channels.empty?
        p(class: "text-sm text-text-secondary") { t(".channel.none") }
      else
        render Components::ChannelSelect.new(
          name: "roles[channel_id]",
          options: channels,
          selected: @setting.channel_id,
          placeholder: t(".channel.placeholder"),
          include_blank: true
        )
      end
    end
  end

  def role_sets_section
    div do
      p(class: "mb-3 text-[11px] font-semibold uppercase tracking-widest text-eyebrow") { t(".sets.label") }
      div(class: "flex flex-col gap-3", data: {role_sets_target: "list"}) do
        @setting.role_sets.each_with_index { |set, index| render card_for(set, index) }
      end
      template(data: {role_sets_target: "template"}) { render new_card }
      add_button
    end
  end

  def card_for(set, index)
    card(
      index: index,
      set_id: set.id,
      name: set.name,
      selection_mode: set.selection_mode,
      channel_override: set.channel_override,
      selected_role_ids: set.assignable_roles.map(&:role_id)
    )
  end

  def new_card
    card(index: "NEW_RECORD", open: true)
  end

  def card(**attrs)
    Components::Roles::RoleSetCard.new(
      channels: channels,
      role_options: role_options,
      channels_by_id: channels_by_id,
      default_channel_id: @setting.channel_id,
      any_unassignable: assignable_options.any_unassignable?,
      **attrs
    )
  end

  def add_button
    button(
      type: "button",
      data: {action: "role-sets#add"},
      class: "mt-3 flex h-11 w-full items-center justify-center gap-2 rounded-card border border-dashed " \
        "border-border-strong text-sm font-semibold text-text-secondary transition-colors " \
        "hover:border-accent hover:bg-accent-soft hover:text-accent-soft-fg"
    ) do
      render Components::Icon.new("plus", class: "size-4")
      span { t(".sets.add") }
    end
  end

  def channels
    @channels ||= ChannelOptions.new(@config).options
  end

  def channels_by_id
    @channels_by_id ||= channels.to_h { |option| [option.value.to_i, option.label] }
  end

  def assignable_options
    @assignable_options ||= AssignableRoleOptions.new(@config)
  end

  def role_options
    @role_options ||= assignable_options.options
  end
end
