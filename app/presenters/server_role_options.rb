# frozen_string_literal: true

class ServerRoleOptions
  DEFAULT_COLOR = "#99aab5"

  def initialize(server_configuration)
    @config = server_configuration
  end

  def options
    @config.server_roles.order(:position).map do |role|
      Components::TomSelect::Option.for(
        value: role.discord_id,
        label: role.name,
        color: color_hex(role.color)
      )
    end
  end

  def names_by_id
    @config.server_roles.to_h { |role| [role.discord_id, role.name] }
  end

  private

  def color_hex(color)
    return DEFAULT_COLOR if color.nil? || color.zero?

    format("#%06x", color & 0xFFFFFF)
  end
end
