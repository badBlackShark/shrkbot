# frozen_string_literal: true

class Components::TwilightStruggle::InheritNote < Components::Base
  def initialize(visible_when:)
    @visible_when = visible_when
  end

  def view_template(&)
    p(class: "mt-2 hidden text-xs text-text-secondary #{@visible_when}", &)
  end
end
