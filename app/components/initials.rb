# frozen_string_literal: true

module Components
  module Initials
    private

    def initials(name)
      name.split.filter_map { |word| word[0] }.first(2).join.upcase
    end
  end
end
