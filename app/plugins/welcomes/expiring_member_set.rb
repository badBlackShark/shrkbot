# frozen_string_literal: true

module Welcomes
  class ExpiringMemberSet
    INSTANCE_MUTEX = Mutex.new

    class << self
      def retention(value = nil)
        @retention = value if value
        @retention
      end

      def instance
        INSTANCE_MUTEX.synchronize { @instance ||= new }
      end
    end

    def initialize
      @mutex = Mutex.new
      @expiries = {}
    end

    def remember(guild_id:, user_id:, at: Time.current)
      @mutex.synchronize do
        sweep(at)
        @expiries[key(guild_id, user_id)] = at + self.class.retention
      end
      nil
    end

    def forget(guild_id:, user_id:, at: Time.current)
      @mutex.synchronize do
        sweep(at)
        !@expiries.delete(key(guild_id, user_id)).nil?
      end
    end

    private

    def key(guild_id, user_id)
      [guild_id, user_id]
    end

    def sweep(at)
      @expiries.delete_if { |_key, expiry| expiry <= at }
    end
  end
end
