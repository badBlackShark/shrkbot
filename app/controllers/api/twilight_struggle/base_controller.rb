# frozen_string_literal: true

module Api
  module TwilightStruggle
    class BaseController < ActionController::API
      class UnknownTournament < StandardError
        attr_reader :field

        def initialize(field)
          @field = field
          super("#{field} does not match a known tournament")
        end
      end

      rescue_from UnknownTournament, with: :render_unknown_reference

      private

      def render_upsert(result, created:)
        return render_errors(result.errors) if result.failure?

        record = result.value
        render json: {id: record.id, external_id: record.external_id}, status: created ? :created : :ok
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
