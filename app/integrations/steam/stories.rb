# frozen_string_literal: true

module Integrations
  module Steam
    class Stories
      WINDOW = 15.minutes

      def initialize(recent)
        @recent_by_subject = recent.index_by(&:subject_key)
        @pool = recent.dup
      end

      def assign(events)
        events.sort_by { |event| order_key(event) }.each do |event|
          known = @recent_by_subject[event.subject_key]
          if known
            event.story_key = known.story_key
          else
            event.story_key = story_key_for(event)
            @pool << event
          end
        end
        events
      end

      private

      def story_key_for(event)
        options = candidates(event).map(&:story_key).uniq
        options.find { |key| members(key).none? { |member| member.feed_name == event.feed_name } } || event.subject_key
      end

      def candidates(event)
        title = normalised_title(event)
        @pool
          .select { |other| normalised_title(other) == title && (other.occurred_at - event.occurred_at).abs <= WINDOW }
          .sort_by { |other| order_key(other) }
      end

      def members(story_key)
        @pool.select { |member| member.story_key == story_key }
      end

      def normalised_title(event)
        event.title.downcase.gsub(/[^[:alnum:]]+/, " ").strip
      end

      def order_key(event)
        [event.occurred_at, event.subject_key]
      end
    end
  end
end
