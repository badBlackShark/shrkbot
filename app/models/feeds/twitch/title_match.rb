# frozen_string_literal: true

module Feeds
  module Twitch
    module TitleMatch
      ROMAN = %w[ii iii iv v vi vii viii ix x xi xii xiii xiv xv xvi xvii xviii xix xx]
        .each_with_index.to_h { |numeral, index| [numeral, (index + 2).to_s] }.freeze

      def self.names?(title, category)
        wanted = words(category)
        wanted.any? && words(title).each_cons(wanted.size).include?(wanted)
      end

      def self.words(text)
        ActiveSupport::Inflector.transliterate(text.downcase)
          .gsub("&", " and ")
          .split(/[^a-z0-9]+/)
          .compact_blank
          .map { |word| ROMAN.fetch(word, word) }
      end
      private_class_method :words
    end
  end
end
