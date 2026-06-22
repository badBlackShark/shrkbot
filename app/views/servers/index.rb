# frozen_string_literal: true

class Views::Servers::Index < Views::Base
  def initialize(present:, absent:, user:, error: false)
    @present = present
    @absent = absent
    @user = user
    @error = error
  end

  def view_template
    render Components::AppShell.new(user: @user) do
      div(class: "mx-auto max-w-4xl px-6 py-10") do
        div(class: "mb-6") do
          h1(class: "mb-1 font-display text-2xl font-bold tracking-tight") { "Your servers" }
          p(class: "text-ink-600") { "Pick a server to configure. Servers without shrkbot show an invite link instead." }
        end

        error_banner if @error

        if @present.empty? && @absent.empty?
          empty_state
        else
          div(class: "grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3") do
            @present.each { |guild| present_card(guild) }
            @absent.each { |guild| invite_card(guild) }
          end
        end
      end
    end
  end

  private

  def present_card(guild)
    a(href: "#", class: "card-lift flex flex-col gap-3 rounded-lg border border-ink-200 bg-ink-0 p-5 shadow-sm") do
      card_heading(guild)
      span(class: "self-start rounded-full bg-brand-100 px-2.5 py-1 text-xs font-semibold text-accent-soft-fg") { "Configure" }
    end
  end

  def invite_card(guild)
    div(class: "flex flex-col gap-3 rounded-lg border border-dashed border-ink-300 bg-ink-0 p-5") do
      card_heading(guild)
      a(href: invite_url(guild), class: "self-start rounded-md border border-ink-300 px-3 py-1.5 text-sm font-semibold hover:bg-ink-50") { "Invite shrkbot" }
    end
  end

  def card_heading(guild)
    div(class: "flex items-center gap-3") do
      avatar(guild)
      span(class: "truncate font-semibold") { guild.name }
    end
  end

  def avatar(guild)
    if guild.icon_url
      img(src: guild.icon_url, alt: "", loading: "lazy", class: "h-12 w-12 flex-none rounded-lg object-cover")
    else
      span(class: "grid h-12 w-12 flex-none place-items-center rounded-lg bg-ink-100 font-semibold text-ink-500") { initials(guild.name) }
    end
  end

  def empty_state
    div(class: "rounded-lg border border-dashed border-ink-300 bg-ink-0 p-10 text-center") do
      h2(class: "text-lg font-bold") { "shrkbot isn't in any of your servers yet" }
      p(class: "mx-auto mt-2 max-w-md text-sm text-ink-600") { "You need Manage Server permissions and shrkbot must be present. Invite it to a server, then come back and refresh." }
    end
  end

  def error_banner
    div(class: "mb-6 rounded-md border border-warning/30 bg-warning-soft px-4 py-3 text-sm text-warning") { "We couldn't reach Discord to load your servers. Try again in a moment." }
  end

  def initials(name)
    name.split.filter_map { |word| word[0] }.first(2).join.upcase
  end

  def invite_url(guild)
    client_id = ENV["CLIENT_ID"]
    "https://discord.com/oauth2/authorize?client_id=#{client_id}&scope=bot+applications.commands&guild_id=#{guild.id}&disable_guild_select=true"
  end
end
