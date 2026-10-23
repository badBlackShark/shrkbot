# frozen_string_literal: true

module Ops
  module Feeds
    module Posts
      class Prune < ApplicationOperation
        def call
          ::Feeds::Post.where(created_at: ...::Ops::Integrations::Prune::RETENTION.ago).delete_all
          ok
        end
      end
    end
  end
end
