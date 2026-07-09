# frozen_string_literal: true

module Ops
  module Moderation
    module Phashes
      class MarkSeen < ApplicationOperation
        TOUCH_INTERVAL = 1.hour

        receives :phash_hex

        def call
          phash = ::Moderation::Phash.find_by(phash: phash_hex)
          return ok unless phash
          return ok if phash.last_seen_at > TOUCH_INTERVAL.ago

          phash.update!(last_seen_at: Time.current)
          ok(phash)
        end
      end
    end
  end
end
