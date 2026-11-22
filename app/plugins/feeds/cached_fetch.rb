# frozen_string_literal: true

module Feeds
  module CachedFetch
    TTL = 1.day
    FAILURE_TTL = 10.minutes

    def self.call(key, missing:, errors: [Integrations::Error], ttl: TTL, failure_ttl: FAILURE_TTL, &)
      Rails.cache.fetch(key, expires_in: ttl, &)
    rescue *errors => error
      Rails.logger.warn("Feeds: no #{missing}: #{error.class}: #{error.message}")
      Rails.cache.write(key, nil, expires_in: failure_ttl) if failure_ttl
      nil
    end
  end
end
