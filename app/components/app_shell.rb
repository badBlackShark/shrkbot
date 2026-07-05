# frozen_string_literal: true

class Components::AppShell < Components::Base
  include Phlex::Rails::Helpers::ImageTag
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::TurboFrameTag

  def initialize(user:, current_server: nil, current_server_id: nil, servers: [], plugin_counts: {}, sidebar: nil)
    @user = user
    @current_server = current_server
    @current_server_id = current_server_id
    @servers = servers
    @plugin_counts = plugin_counts
    @sidebar = sidebar
  end

  def view_template(&block)
    div(class: "flex min-h-screen flex-col") do
      top_bar
      if @sidebar
        div(class: "flex flex-1") do
          render @sidebar
          main(class: "min-w-0 flex-1") { yield }
        end
      else
        main(class: "flex-1") { yield }
      end
    end
  end

  private

  def top_bar
    header(class: "app-bar z-30 flex h-16 flex-none items-center gap-3 px-5") do
      wordmark
      server_switcher if @current_server
      div(class: "flex-1")
      notification_frame
      render Components::ThemeToggle.new
      user_menu
    end
  end

  def server_switcher
    details(class: "group relative", data: {controller: "dropdown"}) do
      summary(
        data: {action: "click->dropdown#toggle"},
        class: "flex h-9 cursor-pointer list-none items-center gap-2 rounded-md px-2 transition-colors hover:bg-surface-sunken [&::-webkit-details-marker]:hidden"
      ) do
        render Components::ServerAvatar.new(server: @current_server, size: :sm)
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
      render Components::ServerAvatar.new(server:, size: :md)
      div(class: "min-w-0 flex-1") do
        p(class: "truncate text-sm font-semibold") { server.name }
        p(class: "text-[11px] text-text-secondary") { t(".plugins_on", count: @plugin_counts[server.id].to_i) }
      end
      render Components::Icon.new("check", class: "size-4 flex-none text-accent") if current
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

  def notification_frame
    turbo_frame_tag(
      "notifications",
      src: notifications_path(server_id: @current_server_id || @current_server&.id),
      loading: "eager"
    ) do
      placeholder_bell
    end
  end

  def placeholder_bell
    button(
      type: "button",
      aria_label: t(".notifications"),
      class: "flex size-9 items-center justify-center rounded-md text-text-secondary transition-colors hover:bg-surface-sunken"
    ) do
      render Components::Icon.new("bell", class: "size-5")
    end
  end

  def user_menu
    details(class: "relative", data: {controller: "dropdown"}) do
      summary(
        data: {action: "click->dropdown#toggle"},
        class: "flex h-10 cursor-pointer list-none items-center gap-2 rounded-full pl-1 pr-2.5 transition-colors hover:bg-surface-sunken [&::-webkit-details-marker]:hidden"
      ) do
        render Components::UserAvatar.new(user: @user, size: :sm)
        span(class: "hidden text-sm font-medium sm:block") { @user.display_name }
        render Components::Icon.new("caret-down", class: "dropdown-chevron size-4 text-text-muted")
      end

      div(
        data: {dropdown_target: "menu"},
        class: "dropdown-menu absolute right-0 top-12 z-40 w-52 rounded-lg border border-border-default bg-surface-card p-1.5 shadow-lg"
      ) do
        a(
          href: account_path,
          class: "flex w-full items-center gap-2.5 rounded-md px-2.5 py-2 text-sm text-text-secondary transition-colors hover:bg-surface-sunken"
        ) do
          render Components::Icon.new("user", class: "size-4")
          span { t(".account") }
        end
        div(class: "mx-1 my-1 h-px bg-surface-sunken")
        if @user.owner?
          a(
            href: admin_settings_path,
            class: "flex w-full items-center gap-2.5 rounded-md px-2.5 py-2 text-sm text-text-secondary transition-colors hover:bg-surface-sunken"
          ) do
            render Components::Icon.new("shield", class: "size-4")
            span { t(".admin_settings") }
          end
          div(class: "mx-1 my-1 h-px bg-surface-sunken")
        end
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
end
