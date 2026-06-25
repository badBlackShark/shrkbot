# frozen_string_literal: true

class Views::Home < Views::Base
  include Phlex::Rails::Helpers::ButtonTo

  def view_template
    div(class: "mx-auto flex min-h-screen max-w-md flex-col justify-center px-5") do
      render Components::Card.new(padding: :lg) do
        h1(class: "mb-2 font-display text-2xl font-bold tracking-tight text-text-primary") do
          span(class: "text-accent") { "shrk" }
          plain "bot"
        end

        p(class: "mb-6 text-text-secondary") { t(".tagline") }

        button_to(
          "/auth/discord",
          method: :post,
          data: {turbo: false},
          class: Components::Button.css(variant: :primary, size: :lg, full: true)
        ) do
          render Components::Icon.new("sign-in", class: "size-4")
          span { t(".sign_in") }
        end
      end
    end
  end
end
