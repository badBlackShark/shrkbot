# frozen_string_literal: true

module Ops
  module TwilightStruggle
    module Tournaments
      class Destroy < ApplicationOperation
        receives :tournament

        def call
          tournament.destroy!
          ok
        end
      end
    end
  end
end
