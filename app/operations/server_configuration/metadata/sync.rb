# frozen_string_literal: true

module Ops
  module ServerConfiguration
    module Metadata
      class Sync < ApplicationOperation
        receives :server_configuration, :name, :icon_hash, :member_count

        def call
          server_configuration.update!(name:, icon_hash:, member_count:)
          ok(server_configuration)
        end
      end
    end
  end
end
