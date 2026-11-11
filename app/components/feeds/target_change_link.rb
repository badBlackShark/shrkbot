# frozen_string_literal: true

class Components::Feeds::TargetChangeLink < Components::Base
  def initialize(href:)
    @href = href
  end

  def view_template
    a(href: @href, class: Components::Feeds::TargetCard::LINK) { t(".label") }
  end
end
