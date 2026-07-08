# frozen_string_literal: true

module Moderation
  module FuzzyMatcher
    module_function

    def match?(pattern, text, ratio: 0.2)
      return pattern.match?(text) if pattern.is_a?(Regexp)
      return true if text.include?(pattern)

      max_dist = (pattern.length * ratio).floor
      return false if max_dist <= 0

      fuzzy_substring_distance(pattern, text) <= max_dist
    end

    def fuzzy_substring_distance(pattern, text)
      m = pattern.length
      n = text.length
      return m if n.zero?

      prev = Array.new(n + 1, 0)
      (1..m).each do |i|
        cur = Array.new(n + 1, 0)
        cur[0] = i
        pc = pattern[i - 1]
        (1..n).each do |j|
          cost = (pc == text[j - 1]) ? 0 : 1
          cur[j] = [prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost].min
        end
        prev = cur
      end
      prev.min
    end

    private_class_method :fuzzy_substring_distance
  end
end
