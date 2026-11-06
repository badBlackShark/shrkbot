# frozen_string_literal: true

module Feeds
  module Twitch
    class TitleHistory
      Entry = Data.define(:title, :category, :seconds)
      MIN_SECONDS = 5.minutes.to_i
      MAX_LINES = 15

      def self.for(ended)
        changes = Integrations::Event
          .in_story(ended.watch_id, ended.story_key)
          .where(type: [Integrations::Twitch::StreamStarted.name, Integrations::Twitch::StreamUpdated.name])
          .order(:occurred_at, :created_at, :id)
        new(changes.to_a, ended_at: Time.iso8601(ended.ended_at)).entries
      end

      def initialize(changes, ended_at:)
        @changes = changes.select { |change| change.is_a?(Integrations::Twitch::StreamStarted) || change.occurred_at < ended_at }
        @ended_at = ended_at
      end

      def entries
        merged(held_long_enough(spans))
      end

      private

      attr_reader :changes, :ended_at

      def spans
        starts = changes.map { |change| start_of(change) }
        ends = starts.drop(1) + [ended_at]
        changes.zip(starts, ends).map do |change, from, to|
          Entry.new(title: change.title, category: change.category_name, seconds: (to - from).to_i)
        end
      end

      def start_of(change)
        if change.is_a?(Integrations::Twitch::StreamStarted)
          Time.iso8601(change.started_at)
        else
          change.occurred_at
        end
      end

      def held_long_enough(spans)
        spans.select { |span| span.seconds >= MIN_SECONDS }
      end

      def merged(spans)
        spans.each_with_object([]) do |span, result|
          last = result.last
          if last && last.title == span.title && last.category == span.category
            result[-1] = last.with(seconds: last.seconds + span.seconds)
          else
            result << span
          end
        end
      end
    end
  end
end
