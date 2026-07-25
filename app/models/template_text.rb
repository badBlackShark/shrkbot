# frozen_string_literal: true

module TemplateText
  module_function

  def render(template, tokens)
    tokens.reduce(template.to_s) do |text, (token, value)|
      text.gsub("{#{token}}") { value.to_s }
    end
  end
end
