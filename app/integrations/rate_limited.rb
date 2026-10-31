# frozen_string_literal: true

module Integrations
  class RateLimited < Error
    attr_reader :retry_after, :headers

    def initialize(message = nil, retry_after: nil, headers: {})
      super(message)
      @retry_after = retry_after
      @headers = headers
    end
  end
end
