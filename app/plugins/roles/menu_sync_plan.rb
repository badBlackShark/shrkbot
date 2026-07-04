# frozen_string_literal: true

module Roles
  class MenuSyncPlan
    def initialize
      @deletes = []
      @role_sets = []
    end

    def delete(channel_id:, message_id:)
      return if channel_id.nil? || message_id.nil?

      @deletes << {channel_id:, message_id:}
    end

    def post(role_set)
      @role_sets << role_set
    end

    def publish
      @deletes.each { |del| ConfigBus.delete_roles_message(**del) }
      @role_sets.each { |set| ConfigBus.post_roles(set) }
    end
  end
end
