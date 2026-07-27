# frozen_string_literal: true

class Components::BespokePluginsLink < Components::Base
  def view_template
    a(
      href: bespoke_plugins_path,
      class: "hidden items-center gap-2 rounded-md px-2.5 py-2 text-sm font-medium text-text-secondary transition-colors hover:bg-surface-sunken hover:text-text-primary sm:flex"
    ) do
      render Components::Icon.new("puzzle-piece", class: "size-4")
      span { t(".label") }
    end
  end
end
