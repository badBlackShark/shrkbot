# frozen_string_literal: true

class Views::Home < Views::Base
  include Phlex::Rails::Helpers::ButtonTo

  def view_template
    div(class: "mx-auto max-w-md") do
      h1(class: "mb-2 text-3xl font-bold") { "shrkbot" }
      p(class: "mb-6 text-gray-600") { "Sign in to configure shrkbot for your servers." }
      button_to(
        "Sign in with Discord",
        "/auth/discord",
        method: :post,
        data: {turbo: false},
        class: "rounded-md bg-[#39afe5] px-4 py-2 font-medium text-white hover:brightness-95"
      )
    end
  end
end
