# frozen_string_literal: true

module VerifiesGuildRoles
  extend ActiveSupport::Concern

  private

  def guild_roles?(*role_ids)
    ids = role_ids.flatten.compact_blank.map(&:to_s).uniq
    ids.empty? || @server_configuration.server_roles.where(discord_id: ids).count == ids.size
  end
end
