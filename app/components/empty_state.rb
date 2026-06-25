# frozen_string_literal: true

class Components::EmptyState < Components::Base
  include Phlex::Rails::Helpers::ImageTag

  def initialize(title:, body:)
    @title = title
    @body = body
  end

  def view_template(&block)
    div(class: "flex flex-col items-center px-6 py-16 text-center") do
      image_tag("shrkbot-mascot.png", alt: "", class: "mb-6 size-20 rounded-xl opacity-50 shadow-sm")
      h2(class: "mb-2 font-display text-xl font-bold tracking-tight") { @title }
      p(class: "mb-6 max-w-sm text-sm leading-relaxed text-text-secondary") { @body }
      div(class: "flex flex-wrap justify-center gap-3") { yield }
    end
  end
end
