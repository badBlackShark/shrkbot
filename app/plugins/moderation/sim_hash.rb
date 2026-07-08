# frozen_string_literal: true

require "digest"

module Moderation
  module SimHash
    BITS = 64

    module_function

    def fingerprint(text)
      tallied = shingles(text).tally

      return 0 if tallied.empty?

      votes = Array.new(BITS, 0)

      tallied.each do |shingle, weight|
        bits = hash64(shingle)
        BITS.times do |i|
          votes[i] += (bits[i] == 1) ? weight : -weight
        end
      end

      result = 0
      BITS.times do |i|
        result |= (1 << i) if votes[i] > 0
      end
      result
    end

    def similar?(a, b, similarity: 1.0)
      hamming_distance(a, b) <= ((1.0 - similarity) * BITS).floor
    end

    def hamming_distance(a, b)
      (a ^ b).to_s(2).count("1")
    end

    def shingles(text)
      tokens = text.to_s.split
      tokens + tokens.each_cons(2).map { |a, b| "#{a} #{b}" }
    end

    def hash64(shingle)
      Digest::SHA1.digest(shingle).unpack1("Q>")
    end

    private_class_method :shingles, :hash64
  end
end
