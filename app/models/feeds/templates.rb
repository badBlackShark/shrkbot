# frozen_string_literal: true

module Feeds
  module Templates
    DEFAULTS = {
      "Integrations::Steam::PatchNotesPublished" => "New {game} patch notes: {title}",
      "Integrations::Steam::AnnouncementPublished" => "New {game} announcement: {title}",
      "Integrations::Steam::ArticlePublished" => "{feed}: {title}"
    }.freeze
    TOKENS_BY_SOURCE = {steam: %w[game title url author feed]}.freeze
    OPTIONAL_TOKENS = %w[author].freeze

    EDGE_SPACE = /\A[[:space:]]+|[[:space:]]+\z/

    module_function

    def default(event_type)
      DEFAULTS.fetch(event_type)
    end

    def custom(event_type, text)
      stripped = strip(text)
      stripped unless stripped.empty? || stripped == default(event_type)
    end

    def renders_empty?(template)
      tokens = TOKENS_BY_SOURCE.values.flatten.uniq.index_with { "x" }.merge(OPTIONAL_TOKENS.index_with { "" })
      strip(TemplateText.render(template, tokens)).empty?
    end

    def strip(text)
      text.to_s.gsub(EDGE_SPACE, "")
    end
  end
end
