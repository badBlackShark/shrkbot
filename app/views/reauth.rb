# frozen_string_literal: true

class Views::Reauth < Views::Base
  include Phlex::Rails::Helpers::ButtonTo

  def view_template
    div(class: "mx-auto flex min-h-screen max-w-md flex-col justify-center px-6 text-center") do
      h1(class: "mb-2 font-display text-xl font-bold tracking-tight") { "Signing you back in" }
      p(class: "mb-6 text-ink-600") { "Your Discord sign-in expired. Please stand by - we're refreshing it for you." }
      button_to(
        "Continue",
        "/auth/discord",
        method: :post,
        form: {data: {controller: "reauth", turbo: false}},
        class: "rounded-md bg-brand-500 px-4 py-2 font-medium text-white hover:brightness-95"
      )
    end
  end
end
