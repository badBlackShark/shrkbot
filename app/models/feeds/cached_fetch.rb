# frozen_string_literal: true

module Feeds
  module CachedFetch
    TTL = 1.day
    FAILURE_TTL = 10.minutes

    def self.call(key, missing:, errors: [Integrations::Error], &)
      Rails.cache.fetch(key, expires_in: TTL, &)
    rescue *errors => error
      Rails.logger.warn("Feeds: no #{missing}: #{error.class}: #{error.message}")
      Rails.cache.write(key, nil, expires_in: FAILURE_TTL)
      nil
    end
  end
end
