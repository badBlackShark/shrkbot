# frozen_string_literal: true

module Moderation
  class SpamTracker
    Entry = Data.define(:message_id, :channel_id, :at)
    Hit = Data.define(:entries, :followup) do
      def followup?
        followup
      end
    end
    Bucket = Struct.new(:entries, :triggered_at, :window)
    private_constant :Bucket

    INSTANCE_MUTEX = Mutex.new

    def self.instance
      INSTANCE_MUTEX.synchronize { @instance ||= new }
    end

    def initialize
      @mutex = Mutex.new
      @buckets = {}
    end

    def record(guild_id:, author_id:, fingerprint:, message_id:, channel_id:, at:, window:, threshold:, similarity:)
      @mutex.synchronize do
        sweep_stale(at)
        key = bucket_key(guild_id, author_id, fingerprint, similarity)
        bucket = (@buckets[key] ||= Bucket.new([], nil, window))
        bucket.window = window
        entry = Entry.new(message_id:, channel_id:, at:)

        if bucket.triggered_at && at - bucket.triggered_at <= window
          bucket.triggered_at = at
          return Hit.new(entries: [entry], followup: true)
        end

        bucket.triggered_at = nil
        bucket.entries << entry
        bucket.entries.reject! { |e| e.at < at - window }
        return nil if bucket.entries.map(&:channel_id).uniq.size < threshold

        hit = Hit.new(entries: bucket.entries.dup, followup: false)
        bucket.entries.clear
        bucket.triggered_at = at
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

    def sweep_stale(at)
      @buckets.delete_if do |_key, bucket|
        trigger_expired = bucket.triggered_at.nil? || at - bucket.triggered_at > bucket.window
        entries_expired = bucket.entries.none? { |e| e.at >= at - bucket.window }
        trigger_expired && entries_expired
      end
    end
  end
end
