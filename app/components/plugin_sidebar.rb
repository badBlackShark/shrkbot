# frozen_string_literal: true

class Components::PluginSidebar < Components::Base
  include Components::PluginNav

  def initialize(server_configuration:, active_key:, access:)
    @config = server_configuration
    @active_key = active_key.to_sym
    @access = access
  end

  def view_template
    aside(id: "plugin-sidebar", class: "sticky top-16 hidden h-[calc(100vh-4rem)] w-56 flex-none overflow-y-auto border-r border-border-default bg-surface-sunken md:block") do
      div(class: "p-4") do
        back_link
        div(class: "my-3 h-px bg-border-subtle")
        p(class: "mb-2 px-2 text-[10px] font-semibold uppercase tracking-widest text-eyebrow") { t(".plugins") }
        nav(class: "flex flex-col gap-0.5") do
          all_rows.each do |row|
            next if PluginCatalog.sub_plugin?(row.key)

            item(row)
          end
        end
      end
    end
  end

  private

  def all_rows
    @all_rows ||= PluginStatus.rows(@config, access: @access)
  end

  def item(row)
    return locked_item(row) unless row.manageable
    return group(row) if PluginCatalog.sub_plugin_keys(row.key).any?

    nav_item(row)
  end

  def group(row)
    render Components::SidebarGroup.new(
      label: PluginCatalog.find(row.key).name,
      icon: plugin_icon(row.key),
      open: group_active?(row.key),
      items: group_items(row.key),
      storage_key: "sidebar-group-#{row.key}",
      enabled: row.enabled
    )
  end

  def group_active?(parent)
    @active_key == parent || PluginCatalog.find(@active_key)&.parent == parent
  end

  def group_items(parent)
    overview = {
      label: t(".overview"),
      href: PluginPaths.for(@config, parent),
      active: @active_key == parent,
      status: nil
    }
    [overview] + visible_sub_plugin_keys(parent).map { |key| sub_item(key) }
  end

  def visible_sub_plugin_keys(parent)
    PluginCatalog.sub_plugin_keys(parent) & visible_keys
  end

  def visible_keys
    @visible_keys ||= all_rows.map(&:key)
  end

  def sub_item(key)
    row = all_rows.find { |candidate| candidate.key == key }
    {
      label: PluginCatalog.find(key).name,
      href: PluginPaths.for(@config, key),
      active: @active_key == key,
      status: sub_status(row)
    }
  end

  def sub_status(row)
    return :enabled if row.enabled

    row.configured ? :disabled : :needs_setup
  end

  def back_link
    a(
      href: PluginPaths.dashboard_for(@config.discord_id),
      class: "group flex items-center gap-2 rounded-md px-2 py-1.5 transition-colors hover:bg-surface-card"
    ) do
      render Components::Icon.new("arrow-left", class: "size-4 flex-none text-text-muted")
      span(class: "truncate text-sm font-medium text-text-secondary group-hover:text-text-primary") { @config.name || t(".dashboard") }
    end
  end

  def nav_item(row)
    active = row.key == @active_key
    tone = active ? "bg-accent-soft font-semibold text-accent-soft-fg" : "text-text-secondary hover:bg-surface-card"
    a(
      href: PluginPaths.for(@config, row.key),
      aria_current: ("page" if active),
      class: "flex items-center gap-2.5 rounded-md px-2.5 py-2 transition-colors #{tone}"
    ) do
      item_tile(row, active)
      span(class: "flex-1 text-[13px]") { t("components.plugin_row.plugin.#{row.key}.name") }
      status_dot(row)
    end
  end

  def locked_item(row)
    render Components::Tooltip.new(text: t(".locked"), placement: :down, align: :left, width: "max-w-[11rem]") do
      span(class: "flex cursor-not-allowed items-center gap-2.5 rounded-md px-2.5 py-2 text-text-muted opacity-60") do
        item_tile(row, false)
        span(class: "flex-1 text-[13px]") { t("components.plugin_row.plugin.#{row.key}.name") }
        status_dot(row)
      end
    end
  end

  def item_tile(row, active)
    on = active || row.enabled
    tone = on ? "bg-accent-fill text-white" : "bg-surface-card text-text-muted"
    span(class: "flex size-7 flex-none items-center justify-center rounded-md #{tone}") do
      render Components::Icon.new(plugin_icon(row.key), weight: (on ? :fill : :regular), class: "size-4")
    end
  end

  def status_dot(row)
    tone = row.enabled ? "bg-success" : "bg-border-strong"
    span(class: "size-1.5 flex-none rounded-full #{tone}")
  end
end
