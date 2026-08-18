# frozen_string_literal: true

module Ops
  module ServerConfiguration
    module ServerChannel
      class Destroy < ApplicationOperation
        receives :server_channel

        def call
          ok(server_channel.destroy!)
        end
      end
    end
  end
end
