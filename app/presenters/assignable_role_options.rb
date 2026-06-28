# frozen_string_literal: true

class AssignableRoleOptions
  DEFAULT_COLOR = "#99aab5"

  def initialize(server_configuration)
    @config = server_configuration
  end

  def options
    assignable_roles.map do |role|
      Components::TomSelect::Option.for(
        value: role.discord_id,
        label: role.name,
        color: color_hex(role.color),
        disabled: reason_for(role).present?,
        reason: reason_for(role)
      )
    end
  end

  def any_unassignable?
    assignable_roles.any? { |role| reason_for(role).present? }
  end

  private

  def assignable_roles
    @assignable_roles ||= @config.server_roles
      .where.not(discord_id: @config.discord_id)
      .order(position: :desc)
  end

  def reason_for(role)
    return I18n.t("assignable_roles.managed") if role.managed?
    return I18n.t("assignable_roles.above_bot") if role.position.to_i >= bot_position

    nil
  end

  def bot_position
    @bot_position ||= @config.bot_role_position || 0
  end

  def color_hex(color)
    return DEFAULT_COLOR if color.nil? || color.zero?

    format("#%06x", color & 0xFFFFFF)
  end
end
