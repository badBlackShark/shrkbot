# frozen_string_literal: true

module Ops
  module TwilightStruggle
    module Games
      class Destroy < ApplicationOperation
        receives :game

        def call
          game.destroy!
          ok
        end
      end
    end
  end
end
