# frozen_string_literal: true

module Roles
  class AssignableServerRoles
    def initialize(server_configuration)
      @config = server_configuration
    end

    def candidates
      @candidates ||= @config.server_roles
        .where.not(discord_id: @config.discord_id)
        .order(position: :desc)
    end

    def reason_for(role)
      return :managed if role.managed?
      return :above_bot if bot_position && role.position.to_i >= bot_position

      nil
    end

    def any_unassignable?
      candidates.any? { |role| reason_for(role) }
    end

    def assignable_ids
      candidates.reject { |role| reason_for(role) }.map(&:discord_id)
    end

    private

    def bot_position
      @config.bot_role_position
    end
  end
end
