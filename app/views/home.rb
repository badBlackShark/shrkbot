# frozen_string_literal: true

class Views::Home < Views::Base
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::ImageTag

  def view_template
    div(class: "flex min-h-screen items-center justify-center px-5") do
      render Components::Card.new(padding: :lg, class: "w-[420px] max-w-full text-center") do
        image_tag("shrkbot-mascot.png", alt: "shrkbot", class: "mx-auto size-20 chamfer-tile shadow-md")

        h1(class: "mb-2 mt-5 font-display text-2xl font-bold tracking-tight text-text-primary") do
          plain t(".configure")
          whitespace
          render Components::Wordmark.new
        end

        p(class: "mb-6 text-sm leading-relaxed text-text-secondary") { t(".tagline") }

        button_to(
          "/auth/discord",
          method: :post,
          data: {turbo: false},
          class: Components::Button.css(variant: :primary, size: :lg, full: true)
        ) do
          render Components::Icon.new("sign-in", class: "size-[18px]")
          span { t(".sign_in") }
        end

        p(class: "mt-5 text-xs text-text-muted") { t(".footer") }
      end
    end
  end
end
