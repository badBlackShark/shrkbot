# frozen_string_literal: true

class Components::SiteLogo < Components::Base
  include Phlex::Rails::Helpers::ImageTag

  def initialize(href:)
    @href = href
  end

  def view_template
    a(href: @href, class: "flex items-center gap-2") do
      image_tag("shrkbot-mascot.png", alt: "", class: "size-9 chamfer-tile-sm")
      span(class: "font-display text-lg font-bold tracking-tight") do
        render Components::Wordmark.new
      end
    end
  end
end
