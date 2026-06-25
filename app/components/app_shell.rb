# frozen_string_literal: true

class Components::AppShell < Components::Base
  include Phlex::Rails::Helpers::ImageTag
  include Phlex::Rails::Helpers::ButtonTo

  def initialize(user:, current_server: nil, servers: [], plugin_counts: {})
    @user = user
    @current_server = current_server
    @servers = servers
    @plugin_counts = plugin_counts
  end

  def view_template(&block)
    div(class: "flex min-h-screen flex-col") do
      top_bar
      main(class: "flex-1") { yield }
    end
  end

  private

  def top_bar
    header(class: "app-bar sticky top-0 z-30 flex h-16 flex-none items-center gap-3 px-5") do
      wordmark
      server_switcher if @current_server
      div(class: "flex-1")
      theme_toggle
      user_menu
    end
  end

  def server_switcher
    details(class: "group relative", data: {controller: "dropdown"}) do
      summary(
        data: {action: "click->dropdown#toggle"},
        class: "flex h-9 cursor-pointer list-none items-center gap-2 rounded-md px-2 transition-colors hover:bg-surface-sunken [&::-webkit-details-marker]:hidden"
      ) do
        server_tile(@current_server, size: :sm)
        span(class: "hidden whitespace-nowrap text-sm font-semibold sm:block") { @current_server.name }
        render Components::Icon.new("caret-down", class: "dropdown-chevron size-4 text-text-muted")
      end

      div(
        data: {dropdown_target: "menu"},
        class: "dropdown-menu absolute left-0 top-12 z-40 w-72 overflow-hidden rounded-lg border border-border-default bg-surface-card py-1.5 shadow-lg"
      ) do
        @servers.each { |server| switcher_row(server) }
        div(class: "mx-3 my-1.5 h-px bg-surface-sunken")
        a(
          href: servers_path,
          class: "mx-1.5 flex items-center gap-2.5 rounded-md px-2.5 py-2 text-sm font-medium text-text-secondary transition-colors hover:bg-surface-sunken"
        ) do
          span(class: "flex size-6 flex-none items-center justify-center rounded bg-surface-sunken") do
            render Components::Icon.new("plus", class: "size-3.5")
          end
          plain t(".add_server")
        end
      end
    end
  end

  def switcher_row(server)
    current = server.id == @current_server.id
    tone = current ? "bg-accent-soft hover:bg-accent-soft" : "hover:bg-surface-sunken"
    a(href: server_path(server.id), class: "flex items-center gap-3 px-3 py-2 text-left transition-colors #{tone}") do
      server_tile(server, size: :md)
      div(class: "min-w-0 flex-1") do
        p(class: "truncate text-sm font-semibold") { server.name }
        p(class: "text-[11px] text-text-secondary") { t(".plugins_on", count: @plugin_counts[server.id].to_i) }
      end
      render Components::Icon.new("check", class: "size-4 flex-none text-accent") if current
    end
  end

  def server_tile(server, size:)
    box = (size == :sm) ? "size-7" : "size-8"
    if server.icon_url
      image_tag(server.icon_url, alt: "", loading: "lazy", class: "#{box} flex-none rounded-md object-cover")
    else
      span(class: "#{box} flex flex-none items-center justify-center rounded-md bg-accent-soft text-xs font-bold text-accent-soft-fg") { initials(server.name) }
    end
  end

  def wordmark
    a(href: servers_path, class: "flex items-center gap-2") do
      image_tag("shrkbot-mascot.png", alt: "", class: "size-9 chamfer-tile-sm")
      span(class: "font-display text-lg font-bold tracking-tight") do
        render Components::Wordmark.new
      end
    end
  end

  def theme_toggle
    button(
      type: "button",
      title: t(".toggle_theme"),
      aria_label: t(".toggle_theme"),
      data: {controller: "theme", action: "theme#toggle"},
      class: "flex size-9 items-center justify-center rounded-md text-text-secondary transition-colors hover:bg-surface-sunken"
    ) do
      span(class: "theme-morph size-5") do
        render Components::Icon.new("moon", class: "theme-moon size-5")
        render Components::Icon.new("sun", class: "theme-sun size-5")
      end
    end
  end

  def user_menu
    details(class: "relative", data: {controller: "dropdown"}) do
      summary(
        data: {action: "click->dropdown#toggle"},
        class: "flex h-10 cursor-pointer list-none items-center gap-2 rounded-full pl-1 pr-2.5 transition-colors hover:bg-surface-sunken [&::-webkit-details-marker]:hidden"
      ) do
        avatar
        span(class: "hidden text-sm font-medium sm:block") { @user.display_name }
        render Components::Icon.new("caret-down", class: "dropdown-chevron size-4 text-text-muted")
      end

      div(
        data: {dropdown_target: "menu"},
        class: "dropdown-menu absolute right-0 top-12 z-40 w-52 rounded-lg border border-border-default bg-surface-card p-1.5 shadow-lg"
      ) do
        button_to(
          logout_path,
          method: :delete,
          class: "flex w-full items-center gap-2.5 rounded-md px-2.5 py-2 text-left text-sm text-danger transition-colors hover:bg-danger-soft"
        ) do
          render Components::Icon.new("sign-out", class: "size-4")
          span { t(".log_out") }
        end
      end
    end
  end

  def avatar
    if @user.avatar_url
      image_tag(@user.avatar_url, alt: "", loading: "lazy", class: "size-8 rounded-full object-cover")
    else
      span(class: "flex size-8 items-center justify-center rounded-full bg-accent-soft text-xs font-bold text-accent-soft-fg") { initials(@user.display_name) }
    end
  end

  def initials(name)
    name.split.filter_map { |word| word[0] }.first(2).join.upcase
  end
end
