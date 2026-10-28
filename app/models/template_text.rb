# frozen_string_literal: true

module TemplateText
  module_function

  def render(template, tokens)
    lookup = tokens.transform_keys(&:to_s)
    template.to_s.gsub(/\{(\w+)\}/) do |match|
      name = Regexp.last_match(1)
      lookup.key?(name) ? lookup[name].to_s : match
    end
  end
end
