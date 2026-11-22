# frozen_string_literal: true

module TwilightStruggle
  class GameSequence
    SETTING_KEY = "twilight_struggle_game_watermark"

    def initialize(external_id)
      @external_id = external_id
    end

    def advance
      return set_watermark_only if watermark.nil?
      return [] if arrived_id <= watermark

      candidates = ((watermark + 1)...arrived_id).to_a
      BotSetting.set(SETTING_KEY, arrived_id)
      candidates
    end

    private

    attr_reader :external_id

    def arrived_id
      @arrived_id ||= external_id.to_i
    end

    def watermark
      return @watermark if defined?(@watermark)

      stored = BotSetting.get(SETTING_KEY)
      @watermark = stored&.to_i
    end

    def set_watermark_only
      BotSetting.set(SETTING_KEY, arrived_id)
      []
    end
  end
end
