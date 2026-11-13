# frozen_string_literal: true

class Components::RequiredMarker < Components::Base
  def view_template
    span(class: "ml-1 text-xs font-semibold text-danger") { "*" }
  end
end
