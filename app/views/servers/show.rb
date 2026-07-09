# frozen_string_literal: true

class Views::Servers::Show < Views::Base
  include Components::PluginNav

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
        render Components::Breadcrumb.new(
          [
            {label: t(".breadcrumb_servers"), href: servers_path},
            {label: @guild.name}
          ]
        )
        server_header
        plugins_section
      end
    end
  end

  private

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
    render Components::ServerAvatar.new(server: @guild, size: :xl)
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
    p(class: "mb-3 text-[11px] font-semibold uppercase tracking-widest text-eyebrow") { t(".plugins") }
    div(class: "flex flex-col gap-3") do
      @plugins.select { |row| plugin_config_path(@guild.id, row.key) && !PluginCatalog.sub_plugin?(row.key) }.each do |row|
        render Components::PluginRow.new(server_id: @guild.id, key: row.key, enabled: row.enabled, configured: row.configured, locked: row.locked)
      end
    end
  end
end
