# frozen_string_literal: true

class Views::Home < Views::Base
  include Phlex::Rails::Helpers::ButtonTo

  def view_template
    div(
      class: "mx-auto max-w-md rounded-lg border border-ink-200 bg-ink-0 p-8 shadow-sm",
      data: {controller: "theme"}
    ) do
      div(class: "mb-6 flex items-center justify-between") do
        h1(class: "font-display text-2xl font-bold tracking-tight text-ink-900") do
          plain "shrk"
          span(class: "text-brand-500") { "bot" }
        end
        theme_toggle
      end

      p(class: "mb-6 text-ink-600") do
        "Turn plugins on or off and set them up - all from one place."
      end

      button_to(
        "/auth/discord",
        method: :post,
        data: {turbo: false},
        class: "btn-fill btn-fill-primary inline-flex w-full items-center justify-center gap-2 rounded-md bg-brand-500 px-4 py-3 font-semibold text-white"
      ) do
        render Components::Icon.new("arrow-right-on-rectangle", class: "size-5")
        span { "Sign in with Discord" }
      end
    end
  end

  private

  def theme_toggle
    button(
      type: "button",
      title: "Toggle dark mode",
      aria_label: "Toggle dark mode",
      data: {action: "theme#toggle"},
      class: "grid size-9 place-items-center rounded-md text-ink-500 transition-colors hover:bg-ink-100"
    ) do
      span(class: "theme-when-light") { render Components::Icon.new("moon", class: "size-5") }
      span(class: "theme-when-dark") { render Components::Icon.new("sun", class: "size-5") }
    end
  end
end
