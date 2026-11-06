# frozen_string_literal: true

module Feeds
  module Twitch
    module Duration
      def self.about(seconds)
        minutes = [(seconds / 60.0).round, 1].max
        hours, rest = minutes.divmod(60)
        parts = []
        parts << "#{hours} h" if hours.positive?
        parts << "#{rest} min" if rest.positive? || hours.zero?
        "about #{parts.join(" ")}"
      end
    end
  end
end
