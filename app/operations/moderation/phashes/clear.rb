# frozen_string_literal: true

module Ops
  module Moderation
    module Phashes
      class Clear < ApplicationOperation
        receives :server_configuration, :phash_hex

        def call
          phash = ::Moderation::Phash.find_by(phash: phash_hex)
          phash&.phash_confirmations&.find_by(server_configuration:)&.destroy!
          ::Moderation::ImageScanning::PhashIndex.invalidate
          ok
        end
      end
    end
  end
end
