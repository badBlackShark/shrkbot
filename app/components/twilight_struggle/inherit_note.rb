# frozen_string_literal: true

class Components::TwilightStruggle::InheritNote < Components::Base
  def view_template(&)
    p(class: "mt-2 text-xs text-text-secondary", &)
  end
end
