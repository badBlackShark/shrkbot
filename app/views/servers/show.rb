# frozen_string_literal: true

class Views::Servers::Show < Views::Base
  include Phlex::Rails::Helpers::ImageTag

  def initialize(guild:, server_configuration:, plugins:, user:, servers: [], plugin_counts: {})
    @guild = guild
    @server_configuration = server_configuration
    @plugins = plugins
    @user = user
    @servers = servers
    @plugin_counts = plugin_counts
  end

  def view_template
    render Components::AppShell.new(user: @user, current_server: @guild, servers: @servers, plugin_counts: @plugin_counts) do
      div(class: "mx-auto max-w-3xl px-6 py-8") do
        breadcrumb
        server_header
        plugins_section
      end
    end
  end

  private

  def breadcrumb
    nav(class: "mb-4 flex items-center gap-1.5 text-xs text-text-secondary") do
      a(href: servers_path, class: "transition-colors hover:text-text-primary") { t(".breadcrumb_servers") }
      render Components::Icon.new("caret-right", class: "size-3")
      span(class: "font-medium text-text-secondary") { @guild.name }
    end
  end

  def server_header
    div(class: "mb-6 flex items-center gap-4") do
      avatar
      div do
        h1(class: "font-display text-2xl font-bold tracking-tight") { @guild.name }
        p(class: "text-sm text-text-secondary") { meta_line }
      end
    end
  end

  def avatar
    if @guild.icon_url
      image_tag(@guild.icon_url, alt: "", loading: "lazy", class: "size-14 flex-none rounded-xl object-cover")
    else
      span(class: "flex size-14 flex-none items-center justify-center rounded-xl bg-accent-soft text-xl font-bold text-accent-soft-fg") { initials(@guild.name) }
    end
  end

  def meta_line
    synced = t(
      ".synced",
      channels: t(".channels", count: @server_configuration.server_channels.count),
      roles: t(".roles", count: @server_configuration.server_roles.count)
    )
    parts = []
    parts << t(".members", count: @guild.member_count, formatted: @guild.member_count.to_fs(:delimited)) if @guild.member_count
    parts << synced
    parts.join(" · ")
  end

  def plugins_section
    p(class: "mb-3 text-[11px] font-semibold uppercase tracking-widest text-text-secondary") { t(".plugins") }
    div(class: "flex flex-col gap-3") do
      @plugins.each do |row|
        render Components::PluginRow.new(server_id: @guild.id, key: row.key, enabled: row.enabled, configured: row.configured)
      end
      render Components::PluginRow.new(server_id: @guild.id, key: :reminders, enabled: true, configured: true, locked: true)
    end
  end

  def initials(name)
    name.split.filter_map { |word| word[0] }.first(2).join.upcase
  end
end
