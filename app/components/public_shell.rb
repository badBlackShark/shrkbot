# frozen_string_literal: true

class Components::PublicShell < Components::Base
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::ImageTag

  def initialize(user: nil)
    @user = user
  end

  def view_template(&block)
    div(class: "flex min-h-screen flex-col") do
      header_bar
      main(class: "flex-1") { yield }
      render Components::SiteFooter.new
    end
  end

  private

  def header_bar
    header(class: "app-bar z-30 flex h-16 items-center gap-3 px-6") do
      a(href: @user ? servers_path : root_path, class: "flex items-center gap-2") do
        image_tag("shrkbot-mascot.png", alt: "shrkbot", class: "size-9 rounded-control")
        span(class: "font-display text-lg font-bold tracking-tight") do
          render Components::Wordmark.new
        end
      end
      render Components::VersionBadge.new
      div(class: "flex-1")
      render Components::ThemeToggle.new
      @user ? dashboard_link : sign_in_button
    end
  end

  def dashboard_link
    a(href: servers_path, class: Components::Button.css(variant: :primary, size: :lg)) do
      render Components::Icon.new("squares-four", class: "size-4")
      span { t(".dashboard") }
    end
  end

  def sign_in_button
    button_to(
      "/auth/discord",
      method: :post,
      data: {turbo: false},
      class: Components::Button.css(variant: :primary, size: :lg)
    ) do
      render Components::Icon.new("sign-in", class: "size-4")
      span { t(".sign_in") }
    end
  end
end
