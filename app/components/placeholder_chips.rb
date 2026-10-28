# frozen_string_literal: true

class Components::PlaceholderChips < Components::Base
  def initialize(tokens:)
    @tokens = tokens
  end

  def view_template
    div(class: "mt-2 flex flex-wrap gap-1.5") do
      @tokens.each do |token, description|
        render Components::TokenChip.new(token:, description:)
      end
    end
  end
end
