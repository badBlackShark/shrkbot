# frozen_string_literal: true

module Integrations
  module Steam
    class ArticlePublished < NewsEvent
      self.secondary = true
    end
  end
end
