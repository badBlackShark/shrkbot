# frozen_string_literal: true

module Lfg
  class Cooldown
    INSTANCE_MUTEX = Mutex.new

    def self.instance
      INSTANCE_MUTEX.synchronize { @instance ||= new }
    end

    def initialize
      @mutex = Mutex.new
      @expiries = {}
    end

    def remaining(guild_id:, user_id:, at:)
      @mutex.synchronize do
        sweep(at)
        expiry = @expiries[key(guild_id, user_id)]
        expiry ? [(expiry - at).ceil, 0].max : 0
      end
    end

    def start(guild_id:, user_id:, at:, ttl:)
      @mutex.synchronize do
        sweep(at)
        @expiries[key(guild_id, user_id)] = at + ttl
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
