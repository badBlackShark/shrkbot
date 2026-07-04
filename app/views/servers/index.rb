# frozen_string_literal: true

class Views::Servers::Index < Views::Base
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
    render Components::Card.new(href: server_path(guild.id), lift: true, class: "flex flex-col gap-3") do
      identity(guild)
      plugins_badge(@plugin_counts[guild.id].to_i)
    end
  end

  def invite_card(guild)
    render Components::Card.new(dashed: true, class: "flex flex-col gap-3") do
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
    render Components::ServerAvatar.new(server: guild, size: :lg, tone: :sunken, dim: muted)
  end

  def plugins_badge(count)
    render Components::Badge.new(variant: count.positive? ? :brand : :neutral, class: "self-start") do
      t(".plugins_enabled", count:)
    end
  end

  def member_label(guild)
    t(".members", count: guild.member_count, formatted: guild.member_count.to_fs(:delimited))
  end

  def invite_button(url)
    render Components::Button.new(
      variant: :secondary,
      href: url,
      icon: "plus",
      label: t(".invite"),
      class: "self-start"
    )
  end

  def missing_server_prompt
    render Components::Card.new(dashed: true, padding: :lg, class: "mt-8 text-center") do
      p(class: "text-sm font-semibold") { t(".missing_title") }
      p(class: "mx-auto mt-1 max-w-md text-sm text-text-secondary") { t(".missing_body") }
      div(class: "mt-4 flex justify-center") { invite_button(generic_invite_url) }
    end
  end

  def empty_state
    render Components::EmptyState.new(title: t(".empty_title"), body: t(".empty_body")) do
      render Components::Button.new(variant: :primary, size: :lg, href: generic_invite_url, icon: "plus", label: t(".invite"))
      render Components::Button.new(variant: :secondary, size: :lg, href: servers_path, icon: "arrows-clockwise", label: t(".refresh"))
    end
  end

  def error_banner
    div(class: "mb-6 rounded-md border border-warning/30 bg-warning-soft px-4 py-3 text-sm text-warning") { t(".error") }
  end

  def generic_invite_url
    "https://discord.com/oauth2/authorize?client_id=#{BotConfig.client_id}&scope=bot+applications.commands"
  end

  def invite_url(guild)
    "#{generic_invite_url}&guild_id=#{guild.id}&disable_guild_select=true"
  end
end
