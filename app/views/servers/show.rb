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
        server_settings_section
      end
    end
  end

  private

  def breadcrumb
    nav(class: "mb-4 flex items-center gap-1.5 text-xs text-ink-500") do
      a(href: servers_path, class: "transition-colors hover:text-ink-700") { t(".breadcrumb_servers") }
      render Components::Icon.new("chevron-right", class: "size-3")
      span(class: "font-medium text-ink-700") { @guild.name }
    end
  end

  def server_header
    div(class: "mb-6 flex items-center gap-4") do
      avatar
      div do
        h1(class: "font-display text-2xl font-bold tracking-tight") { @guild.name }
        p(class: "text-sm text-ink-500") { meta_line }
      end
    end
  end

  def avatar
    if @guild.icon_url
      image_tag(@guild.icon_url, alt: "", loading: "lazy", class: "size-14 flex-none rounded-xl object-cover")
    else
      span(class: "flex size-14 flex-none items-center justify-center rounded-xl bg-brand-100 text-xl font-bold text-accent-soft-fg") { initials(@guild.name) }
    end
  end

  def meta_line
    parts = []
    parts << t(".members", count: @guild.member_count, formatted: @guild.member_count.to_fs(:delimited)) if @guild.member_count
    parts << t(".channels", count: @server_configuration.server_channels.count)
    parts << t(".roles_synced", count: @server_configuration.server_roles.count)
    parts.join(" · ")
  end

  def plugins_section
    p(class: "mb-3 text-[11px] font-semibold uppercase tracking-widest text-ink-500") { t(".plugins") }
    div(class: "flex flex-col gap-3") do
      @plugins.each do |row|
        render Components::PluginRow.new(server_id: @guild.id, key: row.key, enabled: row.enabled, configured: row.configured)
      end
    end
  end

  def server_settings_section
    p(class: "mb-3 mt-8 text-[11px] font-semibold uppercase tracking-widest text-ink-500") { t(".server_settings") }
    div(class: "flex items-center gap-4 rounded-lg border border-ink-200 bg-ink-0 p-5 shadow-sm") do
      div(class: "flex-1") do
        p(class: "text-sm font-medium") { t(".force_dm_title") }
        p(class: "mt-0.5 text-sm text-ink-500") { t(".force_dm_body") }
      end
      render Components::Toggle.new(
        name: :force_dm_reminders,
        checked: @server_configuration.force_dm_reminders,
        label: t(".force_dm_title"),
        url: server_path(@guild.id),
        submit_on_change: true,
        dom_id: "force-dm-toggle"
      )
    end
    remind_note
  end

  def remind_note
    p(class: "mt-3 flex items-start gap-1.5 text-xs text-ink-500") do
      render Components::Icon.new("information-circle", class: "mt-0.5 size-3.5 flex-none")
      span do
        plain t(".remind_note_before")
        span(class: "px-1 font-mono text-ink-600") { "/remind" }
        plain t(".remind_note_after")
      end
    end
  end

  def initials(name)
    name.split.filter_map { |word| word[0] }.first(2).join.upcase
  end
end
