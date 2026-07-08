# frozen_string_literal: true

module Moderation
  module Canonicalizer
    PUNCT_PATTERN = /[[:punct:]]/
    DIGIT_PUNCT_PATTERN = /[[:digit:][:punct:]]/

    module_function

    def call(text, strip_digits: false)
      pattern = strip_digits ? DIGIT_PUNCT_PATTERN : PUNCT_PATTERN

      text.to_s
        .unicode_normalize(:nfkc)
        .gsub(/[​-‏⁠﻿]/, "")
        .downcase
        .gsub(pattern, " ")
        .gsub(/\s+/, " ")
        .strip
    end
  end
end
