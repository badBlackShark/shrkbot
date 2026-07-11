# frozen_string_literal: true

module Roles
  class MenuSyncPlan
    def initialize
      @deletes = []
      @removes = []
      @role_sets = []
    end

    def delete(channel_id:, message_id:)
      return if channel_id.nil? || message_id.nil?

      @deletes << {channel_id:, message_id:}
    end

    def remove(role_set)
      @removes << role_set
    end

    def post(role_set)
      @role_sets << role_set
    end

    def publish
      @deletes.each { |del| Bot::ConfigBus.delete_roles_message(**del) }
      @removes.each { |set| Bot::ConfigBus.remove_roles_menu(set) }
      @role_sets.each { |set| Bot::ConfigBus.post_roles(set) }
    end
  end
end
