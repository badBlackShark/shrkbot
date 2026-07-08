# frozen_string_literal: true

module Ops
  module Moderation
    module Phashes
      class MarkSeen < ApplicationOperation
        receives :phash_hex

        def call
          phash = ::Moderation::Phash.find_by(phash: phash_hex)
          return ok unless phash
          return ok if phash.last_seen_at > 1.hour.ago

          phash.update!(last_seen_at: Time.current)
          ok(phash)
        end
      end
    end
  end
end
