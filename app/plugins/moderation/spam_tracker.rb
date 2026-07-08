# frozen_string_literal: true

module Moderation
  class SpamTracker
    Entry = Data.define(:message_id, :channel_id, :at)

    INSTANCE_MUTEX = Mutex.new

    def self.instance
      INSTANCE_MUTEX.synchronize { @instance ||= new }
    end

    def initialize
      @mutex = Mutex.new
      @buckets = Hash.new { |h, k| h[k] = [] }
    end

    def record(guild_id:, author_id:, fingerprint:, message_id:, channel_id:, at:, window:, threshold:, similarity:)
      @mutex.synchronize do
        key = bucket_key(guild_id, author_id, fingerprint, similarity)
        entries = @buckets[key]
        entries << Entry.new(message_id:, channel_id:, at:)
        entries.reject! { |e| e.at < at - window }

        distinct = entries.map(&:channel_id).uniq
        return nil if distinct.size < threshold

        hit = entries.dup
        @buckets.delete(key)
        hit
      end
    end

    private

    def bucket_key(guild_id, author_id, fingerprint, similarity)
      exact = [guild_id, author_id, fingerprint]
      return exact if similarity >= 1.0 || fingerprint.is_a?(String)

      match = @buckets.keys.find do |g, a, fp|
        g == guild_id && a == author_id && fp.is_a?(Integer) && SimHash.similar?(fp, fingerprint, similarity:)
      end

      match || exact
    end
  end
end
