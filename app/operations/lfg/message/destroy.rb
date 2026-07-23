# frozen_string_literal: true

module Ops
  module Lfg
    module Message
      class Destroy < ApplicationOperation
        receives :message

        def call
          message.destroy!
          ok(message)
        end
      end
    end
  end
end
