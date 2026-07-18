# frozen_string_literal: true

class AssignableRoleOptions
  DEFAULT_COLOR = "#99aab5"

  REASON_KEYS = {
    managed: "assignable_roles.managed",
    above_bot: "assignable_roles.above_bot"
  }.freeze

  def initialize(server_configuration)
    @roles = Roles::AssignableServerRoles.new(server_configuration)
  end

  def options
    @roles.candidates.map do |role|
      reason = reason_text(role)
      Components::TomSelect::Option.for(
        value: role.discord_id,
        label: role.name,
        color: color_hex(role.color),
        disabled: reason.present?,
        reason:
      )
    end
  end

  def any_unassignable?
    @roles.any_unassignable?
  end

  def bot_at_bottom?
    @roles.bot_at_bottom?
  end

  private

  def reason_text(role)
    key = REASON_KEYS[@roles.reason_for(role)]
    key && I18n.t(key)
  end

  def color_hex(color)
    return DEFAULT_COLOR if color.nil? || color.zero?

    format("#%06x", color & 0xFFFFFF)
  end
end
