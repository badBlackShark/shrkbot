# frozen_string_literal: true

module Feeds
  class TargetLookup
    Result = Data.define(:target, :error)

    def self.call(watcher_class, input)
      capture { watcher_class.resolve(input) }
    end

    def self.by_external_id(watcher_class, external_id)
      capture { watcher_class.refresh([external_id]).first || raise(Integrations::NotFound) }
    end

    def self.capture
      Result.new(target: yield, error: nil)
    rescue Integrations::InvalidReference
      Result.new(target: nil, error: :invalid_reference)
    rescue Integrations::NotFound
      Result.new(target: nil, error: :not_found)
    rescue Integrations::Error
      Result.new(target: nil, error: :unavailable)
    end
    private_class_method :capture
  end
end
