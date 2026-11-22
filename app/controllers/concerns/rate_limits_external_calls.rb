# frozen_string_literal: true

module RateLimitsExternalCalls
  extend ActiveSupport::Concern

  class_methods do
    def rate_limit_external_calls(**)
      rate_limit(to: 60, within: 1.minute, by: -> { session[:user_id] }, **)
    end
  end
end
