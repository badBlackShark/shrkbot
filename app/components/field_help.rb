# frozen_string_literal: true

class Components::FieldHelp < Components::Base
  def initialize(**attrs)
    @extra = attrs[:class]
  end

  def view_template(&block)
    p(class: ["mt-1.5 text-xs text-text-muted", @extra], &block)
  end
end
