# frozen_string_literal: true

class Components::AppShell < Components::Base
  include Phlex::Rails::Helpers::ImageTag
  include Phlex::Rails::Helpers::ButtonTo

  def initialize(user:)
    @user = user
  end

  def view_template(&block)
    div(class: "flex min-h-screen flex-col") do
      top_bar
      main(class: "flex-1") { yield }
    end
  end

  private

  def top_bar
    header(class: "sticky top-0 z-30 flex h-16 flex-none items-center gap-3 border-b border-ink-200 bg-ink-0 px-5") do
      wordmark
      div(class: "flex-1")
      theme_toggle
      user_menu
    end
  end

  def wordmark
    a(href: servers_path, class: "flex items-center gap-2") do
      image_tag("shrkbot-mascot.png", alt: "", class: "size-9 rounded-md")
      span(class: "font-display text-lg font-bold tracking-tight") do
        plain "shrk"
        span(class: "text-brand-500") { "bot" }
      end
    end
  end

  def theme_toggle
    button(
      type: "button",
      title: "Toggle dark mode",
      aria_label: "Toggle dark mode",
      data: {controller: "theme", action: "theme#toggle"},
      class: "grid size-9 place-items-center rounded-md text-ink-500 transition-colors hover:bg-ink-100"
    ) do
      span(class: "theme-morph size-5") do
        render Components::Icon.new("moon", class: "theme-moon size-5")
        render Components::Icon.new("sun", class: "theme-sun size-5")
      end
    end
  end

  def user_menu
    details(class: "relative", data: {controller: "dropdown"}) do
      summary(class: "flex h-10 cursor-pointer list-none items-center gap-2 rounded-full pl-1 pr-2.5 transition-colors hover:bg-ink-100 [&::-webkit-details-marker]:hidden") do
        avatar
        span(class: "hidden text-sm font-medium sm:block") { @user.display_name }
        render Components::Icon.new("chevron-down", class: "size-4 text-ink-400")
      end

      div(class: "absolute right-0 top-12 z-40 w-52 rounded-lg border border-ink-200 bg-ink-0 p-1.5 shadow-lg") do
        div(class: "mb-1 border-b border-ink-100 px-2.5 py-2") do
          p(class: "truncate text-sm font-semibold") { @user.display_name }
        end
        button_to(
          logout_path,
          method: :delete,
          class: "flex w-full items-center gap-2.5 rounded-md px-2.5 py-2 text-left text-sm text-danger transition-colors hover:bg-danger-soft"
        ) do
          render Components::Icon.new("arrow-left-on-rectangle", class: "size-4")
          span { "Log out" }
        end
      end
    end
  end

  def avatar
    if @user.avatar_url
      image_tag(@user.avatar_url, alt: "", loading: "lazy", class: "size-8 rounded-full object-cover")
    else
      span(class: "grid size-8 place-items-center rounded-full bg-brand-100 text-xs font-bold text-accent-soft-fg") { initials(@user.display_name) }
    end
  end

  def initials(name)
    name.split.filter_map { |word| word[0] }.first(2).join.upcase
  end
end
