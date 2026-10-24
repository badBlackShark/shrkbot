# frozen_string_literal: true

module Feeds
  class TargetLookup
    Result = Data.define(:target, :error)

    def self.call(watcher_class, input)
      Result.new(target: watcher_class.resolve(input), error: nil)
    rescue Integrations::InvalidReference
      Result.new(target: nil, error: :invalid_reference)
    rescue Integrations::NotFound
      Result.new(target: nil, error: :not_found)
    rescue Integrations::Error
      Result.new(target: nil, error: :unavailable)
    end
  end
end
