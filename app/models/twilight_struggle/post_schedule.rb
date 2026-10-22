# frozen_string_literal: true

module TwilightStruggle
  class PostSchedule
    def initialize(game:, server_configuration:, reported_at:)
      @game = game
      @server_configuration = server_configuration
      @reported_at = reported_at
    end

    def wait
      return 0 if posted_message

      [due_at - Time.current, 0].max
    end

    def config
      @config ||= EffectiveConfig.new(@game.tournament, @server_configuration)
    end

    def posted_message
      return @posted_message if defined?(@posted_message)

      @posted_message = @game.posted_messages.find_by(server_configuration: @server_configuration)
    end

    private

    def due_at
      [@reported_at, @game.created_at].min + config.post_delay
    end
  end
end
