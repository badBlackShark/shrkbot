# frozen_string_literal: true

class Components::Description < Components::Base
  def view_template(&)
    p(class: "mt-0.5 text-sm text-text-secondary", &)
  end
end
