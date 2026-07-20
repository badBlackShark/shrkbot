# frozen_string_literal: true

module Ops
  module Lfg
    module Message
      class Post < ApplicationOperation
        receives :server_configuration, :channel_id, :message_id

        def call
          record = ::Lfg::Message.create!(
            server_configuration:,
            channel_id:,
            message_id:
          )
          ok(record)
        end
      end
    end
  end
end
