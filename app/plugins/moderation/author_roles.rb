# frozen_string_literal: true

module Moderation
  module AuthorRoles
    module_function

    def of(author)
      author.respond_to?(:roles) ? author.roles : []
    end
  end
end
