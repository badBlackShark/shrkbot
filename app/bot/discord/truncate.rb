# frozen_string_literal: true

module Discord
  module Truncate
    module_function

    def call(text, limit)
      text.to_s.truncate(limit, separator: " ", omission: "…")
    end
  end
end
