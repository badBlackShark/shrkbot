# frozen_string_literal: true

class Components::InlineField < Components::Base
  def initialize(label:)
    @label = label
  end

  def view_template
    div(class: "flex flex-wrap items-center gap-2.5") do
      span(class: "text-sm font-semibold") { @label }
      yield
    end
  end
end
