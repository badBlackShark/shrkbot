# frozen_string_literal: true

module Ops
  module ServerConfiguration
    module ServerChannels
      class Destroy < ApplicationOperation
        receives :server_channel

        def call
          ok(server_channel.destroy!)
        end
      end
    end
  end
end
