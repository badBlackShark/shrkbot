# frozen_string_literal: true

module Ops
  module Moderation
    module Phashes
      class Confirm < Upsert
        receives :server_configuration, :phash_hex

        private

        def verdict
          :confirmed
        end
      end
    end
  end
end
