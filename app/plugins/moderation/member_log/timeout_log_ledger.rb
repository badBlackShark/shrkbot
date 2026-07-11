# frozen_string_literal: true

module Moderation
  module MemberLog
    class TimeoutLogLedger
      INSTANCE_MUTEX = Mutex.new

      def self.instance
        INSTANCE_MUTEX.synchronize { @instance ||= new }
      end

      def initialize
        @mutex = Mutex.new
        @logged = {}
      end

      def first_sighting?(guild_id:, user_id:, expires_at:)
        @mutex.synchronize do
          sweep_expired
          key = [guild_id, user_id]
          return false if @logged[key] == expires_at.to_i

          @logged[key] = expires_at.to_i
          true
        end
      end

      private

      def sweep_expired
        now = Time.current.to_i
        @logged.delete_if { |_, expires| expires < now }
      end
    end
  end
end
