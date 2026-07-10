# frozen_string_literal: true

module Moderation
  module AuditLogLookup
    Attribution = Data.define(:moderator, :reason)
    MAX_AGE_SECONDS = 30

    module_function

    def attribution(server, action:, target_id:, &match)
      entry = recent_entries(server, action).find do |candidate|
        candidate.target&.id == target_id && (match.nil? || match.call(candidate))
      end
      return unless entry

      Attribution.new(moderator: entry.user, reason: entry.reason)
    end

    def recent_entries(server, action)
      server.audit_logs(action:, limit: 10).entries.select do |entry|
        Time.current - entry.creation_time <= MAX_AGE_SECONDS
      end
    rescue Discordrb::Errors::NoPermission, Discordrb::Errors::MissingPermissions
      []
    end

    private_class_method :recent_entries
  end
end
