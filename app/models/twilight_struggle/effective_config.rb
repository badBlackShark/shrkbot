# frozen_string_literal: true

module TwilightStruggle
  class EffectiveConfig
    def initialize(tournament, server_configuration)
      @tournament = tournament
      @server_configuration = server_configuration
    end

    def channel_id
      first_set(:discord_channel_id)
    end

    def template_win
      first_set(:template_win) || I18n.t("twilight_struggle.default_template.win")
    end

    def template_tie
      first_set(:template_tie) || I18n.t("twilight_struggle.default_template.tie")
    end

    def template_video
      first_set(:template_video) || I18n.t("twilight_struggle.default_template.video")
    end

    def player_display
      chain.find { |destination| destination.player_display.present? }&.player_display || Destination::DEFAULT_PLAYER_DISPLAY
    end

    def post_delay
      (first_set(:post_delay_seconds) || 0).seconds
    end

    def inherited_from
      chain.first&.tournament
    end

    def source_of(attribute)
      chain.find { |destination| !destination.public_send(attribute).nil? }&.tournament
    end

    private

    def first_set(attribute)
      chain.filter_map { |destination| destination.public_send(attribute) }.first
    end

    def chain
      @chain ||= build_chain
    end

    def build_chain
      return [] if @tournament.nil?

      lineage = @tournament.chain
      by_tournament = Destination
        .active
        .where(tournament: lineage, server_configuration: @server_configuration)
        .index_by(&:tournament_id)
      lineage.filter_map { |tournament| by_tournament[tournament.id] }
    end
  end
end
