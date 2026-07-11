# frozen_string_literal: true

class Components::PageHeading < Components::Base
  def initialize(title:, subtitle:)
    @title = title
    @subtitle = subtitle
  end

  def view_template
    div(class: "mb-6") do
      h1(class: "mb-1 font-display text-2xl font-bold tracking-tight") { @title }
      p(class: "text-text-secondary") { @subtitle }
    end
  end
end
