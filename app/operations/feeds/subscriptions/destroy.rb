# frozen_string_literal: true

module Ops
  module Feeds
    module Subscriptions
      class Destroy < ApplicationOperation
        receives :subscription

        def call
          subscription.destroy!
          ok(subscription)
        end
      end
    end
  end
end
