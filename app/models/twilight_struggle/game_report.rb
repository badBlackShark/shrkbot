# frozen_string_literal: true

module TwilightStruggle
  GameReport = Data.define(:usa, :ussr, :winning_side, :winning_turn, :winning_method, :game_code, :game_date, :video_urls) do
    def initialize(usa:, ussr:, winning_side:, winning_turn: nil, winning_method: nil, game_code: nil, game_date: nil, video_urls: [])
      super
    end

    def self.from_payload(payload)
      payload = payload.symbolize_keys
      new(
        usa: Player.from_payload(payload[:usa]),
        ussr: Player.from_payload(payload[:ussr]),
        winning_side: payload[:winning_side],
        winning_turn: payload[:winning_turn],
        winning_method: payload[:winning_method],
        game_code: payload[:game_code],
        game_date: payload[:game_date],
        video_urls: payload[:video_urls] || []
      )
    end

    def tie?
      winning_side == "tie"
    end

    def winner_side
      return nil if tie?

      winning_side.to_sym
    end

    def loser_side
      return nil if tie?

      (winner_side == :usa) ? :ussr : :usa
    end

    def winner
      return nil if tie?

      (winner_side == :usa) ? usa : ussr
    end

    def loser
      return nil if tie?

      (winner_side == :usa) ? ussr : usa
    end
  end
end
