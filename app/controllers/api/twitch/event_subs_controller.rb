# frozen_string_literal: true

module Api
  module Twitch
    class EventSubsController < ActionController::API
      before_action :verify_signature
      rescue_from JSON::ParserError, KeyError do
        head :bad_request
      end

      def create
        case request.headers["Twitch-Eventsub-Message-Type"]
        when "webhook_callback_verification"
          render plain: payload.fetch("challenge")
        when "notification"
          ::Integrations::Twitch::NotificationJob.perform_later(subscription.fetch("type"), payload.fetch("event"))
          head :no_content
        when "revocation"
          revoked
          head :no_content
        else
          head :bad_request
        end
      end

      private

      def verify_signature
        verified = ::Integrations::Twitch::EventSub.verified?(
          message_id: request.headers["Twitch-Eventsub-Message-Id"],
          timestamp: request.headers["Twitch-Eventsub-Message-Timestamp"],
          body: request.raw_post,
          signature: request.headers["Twitch-Eventsub-Message-Signature"]
        )
        head :forbidden unless verified
      end

      def revoked
        Rails.logger.warn("Integrations: Twitch revoked EventSub #{subscription["type"]} for #{subscription["condition"]}: #{subscription["status"]}")
        ::Integrations::Twitch::EventSubReconcileJob.perform_later
      end

      def subscription
        payload.fetch("subscription")
      end

      def payload
        @payload ||= JSON.parse(request.raw_post)
      end
    end
  end
end
