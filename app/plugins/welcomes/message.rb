# frozen_string_literal: true

module Welcomes
  module Message
    module_function

    def render(template, user:, username:, displayname:, member_count:)
      TemplateText.render(
        template,
        user:,
        username:,
        displayname:,
        membercount: member_count
      )
    end
  end
end
