# frozen_string_literal: true

module Welcomes
  module Message
    module_function

    def render(template, user:, username:, displayname:, member_count:)
      {
        "{user}" => user,
        "{username}" => username,
        "{displayname}" => displayname,
        "{membercount}" => member_count
      }.reduce(template.to_s) { |text, (token, value)| text.gsub(token) { value.to_s } }
    end
  end
end
