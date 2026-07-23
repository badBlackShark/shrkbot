# frozen_string_literal: true

class Components::Lfg::PingableRolesCard < Components::Base
  def initialize(settings:, context:)
    @settings = settings
    @context = context
  end

  def view_template
    div do
      p(class: "mb-3 text-[11px] font-semibold uppercase tracking-widest text-eyebrow") { t(".label") }
      p(class: "mb-3 text-sm text-text-secondary") { t(".help") }
      div(class: "flex flex-col gap-3", data: {pingable_roles_target: "list"}) do
        @settings.pingable_roles.each_with_index { |role, index| render card_for(role, index) }
      end
      template(data: {pingable_roles_target: "template"}) { render new_card }
      add_button
    end
  end

  private

  def card_for(role, index)
    Components::Lfg::PingableRoleCard.new(
      data: Components::Lfg::PingableRoleCardData.new(
        index:,
        role_id: role.role_id,
        required_role_ids: role.required_role_ids || [],
        excluded_role_ids: role.excluded_role_ids || [],
        allowed_channel_ids: role.allowed_channel_ids || [],
        min_membership_days: role.min_membership_days,
        open: false
      ),
      context: @context
    )
  end

  def new_card
    Components::Lfg::PingableRoleCard.new(
      data: Components::Lfg::PingableRoleCardData.empty,
      context: @context
    )
  end

  def add_button
    button(
      type: "button",
      data: {action: "pingable-roles#add"},
      class: "mt-3 flex h-11 w-full items-center justify-center gap-2 rounded-card border border-dashed " \
        "border-border-strong text-sm font-semibold text-text-secondary transition-colors " \
        "hover:border-accent hover:bg-accent-soft hover:text-accent-soft-fg"
    ) do
      render Components::Icon.new("plus", class: "size-4")
      span { t(".add") }
    end
  end
end
