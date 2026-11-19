# frozen_string_literal: true

module SentryHttpScrubber
  ORIGIN = %r{\A[a-z][a-z0-9+.-]*://[^/?#]*}i
  KEPT_BREADCRUMB_KEYS = %i[method status url].freeze
  SPAN_URL_KEY = Sentry::Span::DataConventions::URL

  module_function

  def breadcrumb(breadcrumb, _hint = nil)
    return breadcrumb unless breadcrumb.category == Sentry::Net::HTTP::BREADCRUMB_CATEGORY

    data = breadcrumb.data
    data.slice!(*KEPT_BREADCRUMB_KEYS)
    data[:url] = origin(data[:url])
    breadcrumb
  end

  def transaction(event, _hint = nil)
    event.spans.each do |span|
      next unless span[:op] == Sentry::Net::HTTP::OP_NAME

      scrub_span(span)
    end
    event
  end

  def scrub_span(span)
    method, url = span[:description].split(" ", 2)
    cut = origin(url)
    span[:description] = "#{method} #{cut}"
    span[:data][SPAN_URL_KEY] = cut
  end

  def origin(url)
    url[ORIGIN]
  end

  private_class_method :scrub_span, :origin
end
