# frozen_string_literal: true

class Views::Reauth < Views::Base
  include Phlex::Rails::Helpers::ButtonTo

  def view_template
    div(class: "mx-auto flex min-h-screen max-w-md flex-col justify-center px-6 text-center") do
      h1(class: "mb-2 font-display text-xl font-bold tracking-tight") { t(".title") }
      p(class: "mb-6 text-text-secondary") { t(".body") }
      button_to(
        t(".continue"),
        "/auth/discord",
        method: :post,
        form: {data: {controller: "reauth", turbo: false}},
        class: "rounded-md bg-accent-fill px-4 py-2 font-medium text-white hover:brightness-95"
      )
    end
  end
end
