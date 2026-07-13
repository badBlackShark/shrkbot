# frozen_string_literal: true

module Ops
  module Moderation
    module Phashes
      class SetGlobalScam < ApplicationOperation
        receives :phash_hex, :global

        def call
          phash = ::Moderation::Phash.find_or_create_by!(phash: phash_hex) { |record| record.last_seen_at = Time.current }
          phash.update!(global_scam: global)
          ::Moderation::ImageScanning::PhashIndex.invalidate
          ok(phash)
        end
      end
    end
  end
end
