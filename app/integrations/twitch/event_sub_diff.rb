# frozen_string_literal: true

module Integrations
  module Twitch
    class EventSubDiff
      TYPES = {"stream.online" => "1", "stream.offline" => "1", "channel.update" => "2"}.freeze
      KEPT_STATUSES = %w[enabled webhook_callback_verification_pending].freeze
      ALERT_STATUSES = %w[notification_failures_exceeded version_removed webhook_callback_verification_failed].freeze
      Wanted = Data.define(:type, :version, :broadcaster_id) do
        def key
          [type, version, broadcaster_id]
        end
      end

      def initialize(existing:, broadcaster_ids:, callback:, rebuild: false)
        @existing = existing
        @broadcaster_ids = broadcaster_ids
        @callback = callback
        @rebuild = rebuild
      end

      def stale
        @stale ||= @existing - kept
      end

      def missing
        @missing ||= wanted.reject { |item| kept_keys.include?(item.key) }
      end

      def revoked
        @revoked ||= @existing.select { |subscription| ALERT_STATUSES.include?(subscription.status) }
      end

      private

      def wanted
        @wanted ||= @broadcaster_ids.flat_map do |broadcaster_id|
          TYPES.map { |type, version| Wanted.new(type:, version:, broadcaster_id:) }
        end
      end

      def wanted_keys
        @wanted_keys ||= wanted.map(&:key)
      end

      def kept
        @kept ||= usable.uniq { |subscription| key_of(subscription) }
      end

      def kept_keys
        @kept_keys ||= kept.map { |subscription| key_of(subscription) }
      end

      def usable
        return [] if @rebuild

        @existing.select do |subscription|
          KEPT_STATUSES.include?(subscription.status) &&
            subscription.callback == @callback &&
            wanted_keys.include?(key_of(subscription))
        end
      end

      def key_of(subscription)
        [subscription.type, subscription.version, subscription.condition["broadcaster_user_id"]]
      end
    end
  end
end
