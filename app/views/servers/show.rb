# frozen_string_literal: true

class Views::Servers::Show < Views::Base
  def initialize(server:, server_configuration:, plugins:, user:, servers: [], plugin_counts: {})
    @server = server
    @server_configuration = server_configuration
    @plugins = plugins
    @user = user
    @servers = servers
    @plugin_counts = plugin_counts
  end

  def view_template
    render Components::AppShell.new(user: @user, current_server: @server, servers: @servers, plugin_counts: @plugin_counts, server_configuration: @server_configuration) do
      div(class: "mx-auto max-w-3xl px-6 py-8") do
        render Components::Breadcrumb.new(
          [
            {label: t(".breadcrumb_servers"), href: servers_path},
            {label: @server.name}
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
        h1(class: "font-display text-2xl font-bold tracking-tight") { @server.name }
        p(class: "text-sm text-text-secondary") { meta_line }
      end
    end
  end

  def avatar
    render Components::ServerAvatar.new(server: @server, size: :xl)
  end

  def meta_line
    synced = t(
      ".synced",
      channels: t(".channels", count: @server_configuration.server_channels.count),
      roles: t(".roles", count: @server_configuration.server_roles.count)
    )
    parts = []
    parts << t(".members", count: @server.member_count, formatted: @server.member_count.to_fs(:delimited)) if @server.member_count
    parts << synced
    parts.join(" · ")
  end

  def plugins_section
    p(class: "mb-3 text-[11px] font-semibold uppercase tracking-widest text-eyebrow") { t(".plugins") }
    div(class: "flex flex-col gap-6") do
      plugin_sections.each_with_index do |rows, index|
        hr(class: "border-border-subtle") if index.positive?
        plugin_section(rows)
      end
    end
  end

  def plugin_sections
    visible_plugins.partition(&:bespoke).reject(&:empty?)
  end

  def plugin_section(rows)
    div(class: "flex flex-col gap-6") do
      rows.partition(&:manageable).reject(&:empty?).each { |group| plugin_group(group) }
    end
  end

  def visible_plugins
    @plugins.select { |row| PluginPaths.for(@server_configuration, row.key) && !PluginCatalog.sub_plugin?(row.key) }
  end

  def plugin_group(rows)
    div(class: "flex flex-col gap-3") do
      rows.each do |row|
        render Components::PluginRow.new(server_configuration: @server_configuration, row:)
      end
    end
  end
end
