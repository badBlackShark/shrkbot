# frozen_string_literal: true

class Components::PlaceholderSection < Components::Base
  def view_template(&block)
    div do
      p(class: "text-sm font-semibold") { t(".label") }
      render Components::CopyableTokens.new(&block)
    end
  end
end
