# frozen_string_literal: true

module Feeds
  class Excerpt
    LIMITS = {"preview" => 500, "full" => 3500}.freeze
    FENCE = "```"
    ELLIPSIS = "…"
    CLOSING = "\n#{FENCE}\n#{ELLIPSIS}"

    def initialize(text, body_length, max: Float::INFINITY)
      @text = text.to_s
      @limit = [LIMITS.fetch(body_length), max - CLOSING.length].min
    end

    def to_s
      return text if text.length <= limit

      kept = text[0, cut_at].rstrip
      return "#{kept}#{ELLIPSIS}" if kept.scan(FENCE).size.even?

      "#{kept}#{CLOSING}"
    end

    private

    attr_reader :text, :limit

    def cut_at
      window = text[0, limit]
      boundary(window, "\n\n", minimum: limit / 2) ||
        boundary(window, "\n", minimum: limit / 2) ||
        boundary(window, " ") ||
        limit
    end

    def boundary(window, separator, minimum: 1)
      index = window.rindex(separator)
      index if index && index >= minimum
    end
  end
end
