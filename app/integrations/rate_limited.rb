# frozen_string_literal: true

module Integrations
  class RateLimited < Error
    attr_reader :retry_after

    def initialize(message = nil, retry_after: nil)
      super(message)
      @retry_after = retry_after
    end
  end
end
