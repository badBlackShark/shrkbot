# frozen_string_literal: true

class Components::Breadcrumb < Components::Base
  def initialize(crumbs)
    @crumbs = crumbs
  end

  def view_template
    nav(aria_label: t(".label"), class: "mb-4 flex items-center gap-1.5 text-xs text-text-secondary") do
      @crumbs.each_with_index do |crumb, index|
        render Components::Icon.new("caret-right", class: "size-3") if index.positive?
        crumb_link(crumb, current: index == @crumbs.size - 1)
      end
    end
  end

  private

  def crumb_link(crumb, current:)
    aria_current = current ? "page" : nil
    if crumb[:href]
      a(href: crumb[:href], aria_current:, class: "transition-colors hover:text-text-primary") { crumb[:label] }
    else
      span(class: "font-medium text-text-secondary", aria_current:) { crumb[:label] }
    end
  end
end
