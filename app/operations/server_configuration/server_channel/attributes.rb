# frozen_string_literal: true

module Ops
  module ServerConfiguration
    module ServerChannel
      module Attributes
        module_function

        def call(channel)
          {
            name: channel[:name],
            channel_type: channel[:channel_type],
            position: channel[:position],
            parent_id: channel[:parent_id]
          }
        end
      end
    end
  end
end
