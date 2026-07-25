# frozen_string_literal: true

class Components::AppShell::MenuItem < Components::Base
  def initialize(href:, icon:, label:)
    @href = href
    @icon = icon
    @label = label
  end

  def view_template
    a(
      href: @href,
      class: "flex w-full items-center gap-2.5 rounded-md px-2.5 py-2 text-sm text-text-secondary transition-colors hover:bg-surface-sunken"
    ) do
      render Components::Icon.new(@icon, class: "size-4")
      span { @label }
    end
  end
end
