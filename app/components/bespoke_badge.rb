# frozen_string_literal: true

class Components::BespokeBadge < Components::Base
  def view_template
    render Components::Badge.new(variant: :copper) do
      render Components::Icon.new("puzzle-piece", weight: :fill, class: "size-3.5")
      plain t(".label")
    end
  end
end
