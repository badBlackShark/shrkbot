# frozen_string_literal: true

class Views::Servers::Index < Views::Base
  include Phlex::Rails::Helpers::ImageTag

  def initialize(present:, absent:, user:, plugin_counts: {}, error: false)
    @present = present
    @absent = absent
    @user = user
    @plugin_counts = plugin_counts
    @error = error
  end

  def view_template
    render Components::AppShell.new(user: @user) do
      div(class: "mx-auto max-w-4xl px-6 py-10") do
        heading
        error_banner if @error

        if @present.empty? && @absent.empty?
          empty_state
        else
          server_grid
          missing_server_prompt
        end
      end
    end
  end

  private

  def heading
    div(class: "mb-6") do
      h1(class: "mb-1 font-display text-2xl font-bold tracking-tight") { t(".title") }
      p(class: "text-text-secondary") { t(".subtitle") }
    end
  end

  def server_grid
    div(class: "grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3") do
      @present.each { |guild| present_card(guild) }
      @absent.each { |guild| invite_card(guild) }
    end
  end

  def present_card(guild)
    a(href: server_path(guild.id), class: "card-lift flex flex-col gap-3 rounded-lg border border-border-default bg-surface-card p-5 shadow-sm") do
      identity(guild)
      plugins_badge(@plugin_counts[guild.id].to_i)
    end
  end

  def invite_card(guild)
    div(class: "flex flex-col gap-3 rounded-lg border border-dashed border-border-strong bg-surface-card p-5") do
      identity(guild, muted: true)
      invite_button(invite_url(guild))
    end
  end

  def identity(guild, muted: false)
    div(class: "flex items-start gap-3") do
      avatar(guild, muted:)
      div(class: "min-w-0") do
        p(class: "text-sm font-semibold line-clamp-2") { guild.name }
        p(class: "text-xs text-text-secondary") { member_label(guild) } if guild.member_count
      end
    end
  end

  def avatar(guild, muted: false)
    dim = muted ? " opacity-60" : ""
    if guild.icon_url
      img(src: guild.icon_url, alt: "", loading: "lazy", class: "size-12 flex-none rounded-lg object-cover#{dim}")
    else
      span(class: "flex size-12 flex-none items-center justify-center rounded-lg bg-surface-sunken font-semibold text-text-secondary#{dim}") { initials(guild.name) }
    end
  end

  def plugins_badge(count)
    tone = count.positive? ? "bg-accent-soft text-accent-soft-fg" : "bg-surface-sunken text-text-secondary"
    span(class: "self-start rounded-full px-2.5 py-1 text-xs font-semibold #{tone}") do
      t(".plugins_enabled", count:)
    end
  end

  def member_label(guild)
    t(".members", count: guild.member_count, formatted: guild.member_count.to_fs(:delimited))
  end

  def invite_button(url)
    a(
      href: url,
      class: "btn-fill btn-fill-ghost inline-flex items-center gap-1.5 self-start rounded-md border border-border-strong px-3 py-1.5 text-sm font-semibold transition-colors hover:bg-surface-sunken"
    ) do
      render Components::Icon.new("plus", class: "size-4")
      span { t(".invite") }
    end
  end

  def missing_server_prompt
    div(class: "mt-8 rounded-lg border border-dashed border-border-default bg-surface-card p-8 text-center") do
      p(class: "text-sm font-semibold") { t(".missing_title") }
      p(class: "mx-auto mt-1 max-w-md text-sm text-text-secondary") { t(".missing_body") }
      div(class: "mt-4 flex justify-center") { invite_button(generic_invite_url) }
    end
  end

  def empty_state
    div(class: "flex flex-col items-center px-6 py-16 text-center") do
      image_tag("shrkbot-mascot.png", alt: "", class: "mb-6 size-20 rounded-xl opacity-50 shadow-sm")
      h2(class: "mb-2 font-display text-xl font-bold tracking-tight") { t(".empty_title") }
      p(class: "mb-6 max-w-sm text-sm leading-relaxed text-text-secondary") { t(".empty_body") }
      div(class: "flex flex-wrap justify-center gap-3") do
        a(
          href: generic_invite_url,
          class: "btn-fill btn-fill-primary inline-flex h-10 items-center gap-2 rounded-md bg-accent-fill px-5 text-sm font-semibold text-white"
        ) do
          render Components::Icon.new("plus", class: "size-4")
          span { t(".invite") }
        end
        a(
          href: servers_path,
          class: "btn-fill btn-fill-ghost inline-flex h-10 items-center gap-2 rounded-md border border-border-default px-5 text-sm font-semibold transition-colors hover:bg-surface-sunken"
        ) do
          render Components::Icon.new("arrows-clockwise", class: "size-4")
          span { t(".refresh") }
        end
      end
    end
  end

  def error_banner
    div(class: "mb-6 rounded-md border border-warning/30 bg-warning-soft px-4 py-3 text-sm text-warning") { t(".error") }
  end

  def initials(name)
    name.split.filter_map { |word| word[0] }.first(2).join.upcase
  end

  def generic_invite_url
    "https://discord.com/oauth2/authorize?client_id=#{ENV["CLIENT_ID"]}&scope=bot+applications.commands"
  end

  def invite_url(guild)
    "#{generic_invite_url}&guild_id=#{guild.id}&disable_guild_select=true"
  end
end
