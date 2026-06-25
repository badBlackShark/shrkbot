# frozen_string_literal: true

class Views::Home < Views::Base
  include Phlex::Rails::Helpers::ButtonTo

  def view_template
    div(class: "mx-auto flex min-h-screen max-w-md flex-col justify-center px-5") do
      div(class: "rounded-lg border border-border-default bg-surface-card p-8 shadow-sm") do
        h1(class: "mb-2 font-display text-2xl font-bold tracking-tight text-text-primary") do
          span(class: "text-accent") { "shrk" }
          plain "bot"
        end

        p(class: "mb-6 text-text-secondary") { t(".tagline") }

        button_to(
          "/auth/discord",
          method: :post,
          data: {turbo: false},
          class: "btn-fill btn-fill-primary inline-flex w-full items-center justify-center gap-2 rounded-md bg-accent-fill px-4 py-3 font-semibold text-white"
        ) do
          render Components::Icon.new("sign-in", class: "size-5")
          span { t(".sign_in") }
        end
      end
    end
  end
end
