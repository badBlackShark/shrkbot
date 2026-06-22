# frozen_string_literal: true

class Views::Home < Views::Base
  include Phlex::Rails::Helpers::ButtonTo

  def view_template
    div(class: "mx-auto flex min-h-screen max-w-md flex-col justify-center px-5") do
      div(class: "rounded-lg border border-ink-200 bg-ink-0 p-8 shadow-sm") do
        h1(class: "mb-2 font-display text-2xl font-bold tracking-tight text-ink-900") do
          span(class: "text-brand-500") { "shrk" }
          plain "bot"
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
  end
end
