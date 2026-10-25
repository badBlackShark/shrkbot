# frozen_string_literal: true

module Feeds
  module Templates
    DEFAULTS = {
      "Integrations::Steam::PatchNotesPublished" => "{role} New {game} patch notes: {title}",
      "Integrations::Steam::AnnouncementPublished" => "{role} New {game} announcement: {title}",
      "Integrations::Steam::ArticlePublished" => "{role} {feed}: {title}"
    }.freeze
    TOKENS_BY_SOURCE = {steam_news: %w[role game title url author feed]}.freeze
    OPTIONAL_TOKENS = %w[role author].freeze

    EDGE_SPACE = /\A[[:space:]]+|[[:space:]]+\z/

    module_function

    def default(event_type)
      DEFAULTS.fetch(event_type)
    end

    def custom(event_type, text)
      stripped = strip(text)
      stripped unless stripped.empty? || stripped == default(event_type)
    end

    def renders_empty?(template, role_id:)
      tokens = TOKENS_BY_SOURCE.values.flatten.uniq.index_with { "x" }.merge(OPTIONAL_TOKENS.index_with { "" })
      tokens["role"] = "x" if role_id
      strip(TemplateText.render(template, tokens)).empty?
    end

    def strip(text)
      text.to_s.gsub(EDGE_SPACE, "")
    end
  end
end
