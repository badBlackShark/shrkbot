# frozen_string_literal: true

module Integrations
  module Twitch
    EventSubSubscription = Data.define(:id, :type, :version, :status, :condition, :callback)
  end
end
