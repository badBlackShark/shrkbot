# frozen_string_literal: true

module Ops
  module Moderation
    module Phashes
      class Prune < ApplicationOperation
        def call
          old = ::Moderation::Phash.where(last_seen_at: ...180.days.ago).where(global_scam: false)
          ::Moderation::PhashConfirmation.where(phash_id: old.select(:id)).delete_all
          old.delete_all
          ::Moderation::Phash.where.missing(:phash_confirmations).where(global_scam: false).delete_all
          ok
        end
      end
    end
  end
end
