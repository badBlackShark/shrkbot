# frozen_string_literal: true

module Integrations
  module OwnerList
    MAX_LISTED = 10

    def self.call(lines)
      listed = lines.first(MAX_LISTED).map { |line| "- #{line}" }
      listed << "- and #{lines.size - MAX_LISTED} more" if lines.size > MAX_LISTED
      listed
    end
  end
end
