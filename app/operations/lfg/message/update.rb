# frozen_string_literal: true

module Ops
  module Lfg
    module Message
      class Update < ApplicationOperation
        receives :message
        receives :notify_reply_id, optional: true
        receives :start_ping_id, optional: true

        def call
          message.notify_reply_id = notify_reply_id unless notify_reply_id.nil?
          message.start_ping_id = start_ping_id unless start_ping_id.nil?
          message.save!
          ok(message)
        end
      end
    end
  end
end
