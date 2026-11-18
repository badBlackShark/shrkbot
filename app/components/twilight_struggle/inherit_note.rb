# frozen_string_literal: true

class Components::TwilightStruggle::InheritNote < Components::Base
  def initialize(visible_when: nil)
    @visible_when = visible_when
  end

  def view_template(&)
    p(class: ["mt-2 text-xs text-text-secondary", ("hidden #{@visible_when}" if @visible_when)], &)
  end
end
