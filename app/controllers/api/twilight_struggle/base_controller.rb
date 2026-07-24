# frozen_string_literal: true

module Api
  module TwilightStruggle
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods

      class UnknownTournament < StandardError
        attr_reader :field

        def initialize(field)
          @field = field
          super("#{field} does not match a known tournament")
        end
      end

      before_action :authenticate_client

      rescue_from UnknownTournament, with: :render_unknown_reference

      private

      def authenticate_client
        authenticate_or_request_with_http_token do |token, _options|
          token.present? && api_keys.any? { |key| ActiveSupport::SecurityUtils.secure_compare(token, key) }
        end
      end

      def api_keys
        ENV.fetch("TWILIGHT_STRUGGLE_API_KEYS", "").split(",").map(&:strip).reject(&:empty?)
      end

      def render_upsert(result)
        return render_errors(result.errors) if result.failure?

        record = result.value
        render json: {id: record.id, external_id: record.external_id}, status: record.previously_new_record? ? :created : :ok
      end

      def render_errors(errors)
        render json: {errors:}, status: :unprocessable_content
      end

      def referenced_tournament(external_id, field)
        return if external_id.blank?

        ::TwilightStruggle::Tournament.find_by(external_id:) || raise(UnknownTournament.new(field))
      end

      def render_unknown_reference(error)
        render_errors([error.message])
      end
    end
  end
end
