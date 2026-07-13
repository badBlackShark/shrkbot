# frozen_string_literal: true

module Moderation
  module ImageScanning
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

      def self.invalidate
        instance.invalidate
      end

      def initialize
        @mutex = Mutex.new
        @by_int = {}
        @loaded_at = nil
      end

      def invalidate
        @mutex.synchronize { @loaded_at = nil }
      end

      def lookup(phash_hex, guild_id)
        @mutex.synchronize do
          refresh_locked
          target = phash_hex.to_i(16)
          match = @by_int.find { |int, _entry| SimHash.hamming_distance(int, target) <= HAMMING_THRESHOLD }
          return :none unless match

          entry = match.last
          own = entry[:verdicts][guild_id]
          if own
            return (own == "confirmed") ? :own_confirmed : :own_dismissed
          end
          return :global_confirmed if entry[:global]

          entry[:verdicts].value?("confirmed") ? :foreign_confirmed : :none
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
        result = Hash.new { |hash, key| hash[key] = {verdicts: {}, global: false} }
        PhashConfirmation
          .joins(:phash, :server_configuration)
          .pluck("phashes.phash", "server_configurations.discord_id", "phash_confirmations.verdict")
          .each { |hex, discord_id, verdict| result[hex.to_i(16)][:verdicts][discord_id] = verdict }
        ::Moderation::Phash.where(global_scam: true).pluck(:phash)
          .each { |hex| result[hex.to_i(16)][:global] = true }
        result
      end
    end
  end
end
