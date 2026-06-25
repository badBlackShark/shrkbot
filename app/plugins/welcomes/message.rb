# frozen_string_literal: true

module Welcomes
  module Message
    module_function

    def render(template, user:, member_count:)
      template.to_s
        .gsub("{user}", user.to_s)
        .gsub("{membercount}", member_count.to_s)
    end
  end
end
