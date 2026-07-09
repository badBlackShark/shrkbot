# frozen_string_literal: true

module Moderation
  class PhashIndex
    INSTANCE_MUTEX = Mutex.new
    HAMMING_THRESHOLD = 4
    REFRESH_INTERVAL = 60

    def self.instance
      INSTANCE_MUTEX.synchronize { @instance ||= new }
    end

    def self.lookup(phash_hex, guild_id)
      instance.lookup(phash_hex, guild_id)
    end

    def initialize
      @mutex = Mutex.new
      @by_int = {}
      @loaded_at = nil
    end

    def lookup(phash_hex, guild_id)
      @mutex.synchronize do
        refresh_locked
        target = phash_hex.to_i(16)
        match = @by_int.find { |int, _verdicts| SimHash.hamming_distance(int, target) <= HAMMING_THRESHOLD }
        return :none unless match

        verdicts = match.last
        own = verdicts[guild_id]
        return (own == "confirmed") ? :own_confirmed : :own_dismissed if own

        verdicts.value?("confirmed") ? :foreign_confirmed : :none
      end
    end

    private

    def refresh_locked
      now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      return if @loaded_at && (now - @loaded_at) < REFRESH_INTERVAL

      @by_int = build
      @loaded_at = now
    end

    def build
      result = Hash.new { |h, k| h[k] = {} }
      PhashConfirmation
        .joins(:phash, :server_configuration)
        .pluck("phashes.phash", "server_configurations.discord_id", "phash_confirmations.verdict")
        .each { |hex, discord_id, verdict| result[hex.to_i(16)][discord_id] = verdict }
      result
    end
  end
end
