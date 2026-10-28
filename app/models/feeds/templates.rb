# frozen_string_literal: true

module Feeds
  module Templates
    TOKENS_BY_SOURCE = {steam: %w[game author feed]}.freeze

    EDGE_SPACE = /\A[[:space:]]+|[[:space:]]+\z/

    module_function

    def custom(text)
      strip(text).presence
    end

    def strip(text)
      text.to_s.gsub(EDGE_SPACE, "")
    end
  end
end
