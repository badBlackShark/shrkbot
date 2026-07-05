# frozen_string_literal: true

class Components::ThemeToggle < Components::Base
  def view_template
    button(
      type: "button",
      title: t(".toggle_theme"),
      aria_label: t(".toggle_theme"),
      data: {controller: "theme", action: "theme#toggle"},
      class: "flex size-9 items-center justify-center rounded-md text-text-secondary transition-colors hover:bg-surface-sunken"
    ) do
      span(class: "theme-morph size-5") do
        render Components::Icon.new("moon", class: "theme-moon size-5")
        render Components::Icon.new("sun", class: "theme-sun size-5")
      end
    end
  end
end
