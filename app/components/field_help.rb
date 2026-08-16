# frozen_string_literal: true

class Components::FieldHelp < Components::Base
  def view_template(&block)
    p(class: "mt-1.5 text-xs text-text-muted", &block)
  end
end
