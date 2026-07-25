# frozen_string_literal: true

module TwilightStruggle
  class EffectiveConfig
    def initialize(tournament)
      @tournament = tournament
    end

    def channel_id
      channel_node&.discord_channel_id
    end

    def server_configuration
      channel_node&.server_configuration
    end

    def template_with_video
      first_present(:template_with_video) || I18n.t("twilight_struggle.default_template.with_video")
    end

    def template_without_video
      first_present(:template_without_video) || I18n.t("twilight_struggle.default_template.without_video")
    end

    def ping_players?
      chain.find { |tournament| !tournament.ping_players.nil? }&.ping_players || false
    end

    private

    def channel_node
      return @channel_node if defined?(@channel_node)

      @channel_node = chain.find { |tournament| tournament.discord_channel_id.present? }
    end

    def first_present(attribute)
      chain.filter_map { |tournament| tournament.public_send(attribute).presence }.first
    end

    def chain
      @chain ||= build_chain
    end

    def build_chain
      nodes = []
      current = @tournament

      while current
        nodes << current
        current = current.parent
      end

      nodes
    end
  end
end
