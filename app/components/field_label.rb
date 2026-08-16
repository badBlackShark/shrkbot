# frozen_string_literal: true

class Components::FieldLabel < Components::Base
  def view_template(&block)
    label(class: "mb-1.5 block text-sm font-semibold", &block)
  end
end
