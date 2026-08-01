# frozen_string_literal: true

module Bot
  class ChannelEvent < BaseEvent
    include FindsServerConfiguration

    def handle
      return unless server_configuration

      apply
    end

    private

    def apply
      raise AbstractMethodError, "#{self.class} must implement #apply"
    end
  end
end
