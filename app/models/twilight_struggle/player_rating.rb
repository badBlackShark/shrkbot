# frozen_string_literal: true

module TwilightStruggle
  class PlayerRating
    def initialize(player)
      @player = player
    end

    def before
      decimal(@player&.rating_before)
    end

    def after
      decimal(@player&.rating_after)
    end

    def change
      return "" if @player&.rating_before.nil? || @player&.rating_after.nil?

      signed(@player.rating_after - @player.rating_before)
    end

    private

    def decimal(value)
      return "" if value.nil?

      whole?(value) ? value.to_i.to_s : value.to_s
    end

    def signed(value)
      rounded = value.round(2)

      "#{"+" if rounded >= 0}#{decimal(rounded)}"
    end

    def whole?(value)
      (value % 1).zero?
    end
  end
end
