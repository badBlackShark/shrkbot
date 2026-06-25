# frozen_string_literal: true

class Components::Wordmark < Components::Base
  def view_template
    span(class: "text-accent") { "shrk" }
    span(class: "text-accent-2-text") { "bot" }
  end
end
