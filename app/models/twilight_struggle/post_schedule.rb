# frozen_string_literal: true

module TwilightStruggle
  class PostSchedule
    def initialize(game:, server_configuration:, reported_at:)
      @game = game
      @server_configuration = server_configuration
      @reported_at = reported_at
    end

    def wait
      return 0 if posted?

      [due_at - Time.current, 0].max
    end

    private

    def due_at
      [@reported_at, Time.current].min + EffectiveConfig.new(@game.tournament, @server_configuration).post_delay
    end

    def posted?
      @game.posted_messages.exists?(server_configuration: @server_configuration)
    end
  end
end
