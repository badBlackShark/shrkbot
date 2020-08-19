require "levenshtein"

module Utilities
  class FuzzyMatch
    def initialize(@haystack : Array(String))
    end

    # Very basic adaptation of https://github.com/seamusabshere/fuzzy_match
    def find(needle : String, min : Float? = nil)
      return "" if needle.empty?

      best_match = ""
      best_distance = 0.0

      @haystack.each do |h|
        distance = dice_coefficient(needle, h)
        next if min && distance < min
        if best_distance < distance
          best_distance = distance
          best_match = h
        elsif best_distance != 0.0 && distance == best_distance
          # If the dice coefficient is the same, resolve with Levenshtein distance.
          best_match = h if Levenshtein.distance(needle, best_match) < Levenshtein.distance(needle, h)
        end
      end

      return best_match
    end

    private def dice_coefficient(s1 : String, s2 : String)
      return 1.0 if s1 == s2

      b1 = get_bigrams(s1)
      b2 = get_bigrams(s2)
      hits = 0
      size = b1.size + b2.size

      b1.each do |p1|
        0.upto(b2.size - 1) do |i|
          if p1 == b2[i]
            hits += 1
            b2.delete_at(i)
            break
          end
        end
      end

      return (2.0 * hits) / (size)
    end

    private def get_bigrams(string : String)
      s = string.downcase
      return (0..s.size - 2).map { |i| s[i, 2] }.reject { |p| p.includes?(" ") }
    end
  end
end
