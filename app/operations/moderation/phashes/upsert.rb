# frozen_string_literal: true

module Ops
  module Moderation
    module Phashes
      class Upsert < ApplicationOperation
        def call
          phash = ::Moderation::Phash.find_or_create_by!(phash: phash_hex) { |record| record.last_seen_at = Time.current }
          confirmation = phash.phash_confirmations.find_or_initialize_by(server_configuration:)
          confirmation.update!(verdict:)
          ok(confirmation)
        end

        private

        def verdict
          raise AbstractMethodError, "#{self.class} must implement #verdict"
        end
      end
    end
  end
end
