# frozen_string_literal: true

module Roles
  class MenuToggle
    def self.publish(server_configuration, enabled:)
      new(server_configuration, enabled:).publish
    end

    def initialize(server_configuration, enabled:)
      @server_configuration = server_configuration
      @enabled = enabled
    end

    def publish
      sets.each do |set|
        if enabled
          plan.post(set)
        elsif set.message_id.present?
          plan.remove(set)
        end
      end
      plan.publish
    end

    private

    attr_reader :server_configuration, :enabled

    def sets
      server_configuration.role_setting.role_sets
    end

    def plan
      @plan ||= MenuSyncPlan.new
    end
  end
end
