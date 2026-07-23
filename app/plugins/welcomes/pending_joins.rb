# frozen_string_literal: true

module Welcomes
  class PendingJoins
    RETENTION = 24.hours

    INSTANCE_MUTEX = Mutex.new

    def self.instance
      INSTANCE_MUTEX.synchronize { @instance ||= new }
    end

    def initialize
      @mutex = Mutex.new
      @expiries = {}
    end

    def remember(guild_id:, user_id:, at: Time.current)
      @mutex.synchronize do
        sweep(at)
        @expiries[key(guild_id, user_id)] = at + RETENTION
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
