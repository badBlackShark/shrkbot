# frozen_string_literal: true

class SentryBreadcrumbScrubber
  HTTP_CATEGORIES = %w[http net.http].freeze
  DROPPED_KEYS = %i[query body].freeze
  TOKEN_PATH = %r{(/(?:interactions|webhooks)/[^/?#]+/)[^/?#]+}
  FILTERED = "[Filtered]"

  def self.call(breadcrumb, _hint = nil)
    return breadcrumb unless HTTP_CATEGORIES.include?(breadcrumb.category)

    data = breadcrumb.data
    data.except!(*DROPPED_KEYS)
    data[:url] = data[:url].to_s.sub(/[?#].*\z/m, "").gsub(TOKEN_PATH, "\\1#{FILTERED}") if data.key?(:url)
    breadcrumb
  end
end
