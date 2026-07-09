# frozen_string_literal: true

module Ops
  module Moderation
    module Phashes
      class Dismiss < Upsert
        receives :server_configuration, :phash_hex

        private

        def verdict
          "dismissed"
        end
      end
    end
  end
end
