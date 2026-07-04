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
    render Components::ChannelCard.new(
      name: "roles[channel_id]",
      channels:,
      selected: @setting.channel_id,
      label: t(".channel.label"),
      help: t(".channel.help")
    )
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
    Components::Roles::RoleSetCard.new(
      data: Components::Roles::RoleSetCardData.new(
        index:,
        set_id: set.id,
        name: set.name,
        selection_mode: set.selection_mode,
        channel_override: set.channel_override,
        selected_role_ids: set.assignable_roles.map(&:role_id),
        open: false,
        repost_path: repost_path_for(set)
      ),
      context: card_context
    )
  end

  def new_card
    Components::Roles::RoleSetCard.new(
      data: Components::Roles::RoleSetCardData.empty,
      context: card_context
    )
  end

  def card_context
    @card_context ||= Components::Roles::RoleFormContext.new(
      channels:,
      role_options:,
      channels_by_id:,
      default_channel_id: @setting.channel_id,
      any_unassignable: assignable_options.any_unassignable?
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

  def channel_options
    @channel_options ||= ChannelOptions.new(@config)
  end

  def channels
    @channels ||= channel_options.options
  end

  def channels_by_id
    @channels_by_id ||= channel_options.labels_by_id
  end

  def assignable_options
    @assignable_options ||= AssignableRoleOptions.new(@config)
  end

  def role_options
    @role_options ||= assignable_options.options
  end

  def repost_path_for(set)
    server_role_set_repost_path(@config.discord_id, set.id)
  end
end
