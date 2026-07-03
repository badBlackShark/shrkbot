# frozen_string_literal: true

class Components::PluginSidebar < Components::Base
  include Components::PluginNav

  def initialize(server_configuration:, active_key:)
    @config = server_configuration
    @active_key = active_key.to_sym
  end

  def view_template
    aside(class: "sticky top-16 hidden h-[calc(100vh-4rem)] w-56 flex-none overflow-y-auto border-r border-border-default bg-surface-sunken md:block") do
      div(class: "p-4") do
        back_link
        div(class: "my-3 h-px bg-border-subtle")
        p(class: "mb-2 px-2 text-[10px] font-semibold uppercase tracking-widest text-eyebrow") { t(".plugins") }
        nav(class: "flex flex-col gap-0.5") do
          items.each { |row| nav_item(row) }
        end
      end
    end
  end

  private

  def items
    PluginStatus.rows(@config).select { |row| plugin_config_path(@config.discord_id, row.key) }
  end

  def back_link
    a(
      href: server_path(@config.discord_id),
      class: "group flex items-center gap-2 rounded-md px-2 py-1.5 transition-colors hover:bg-surface-card"
    ) do
      render Components::Icon.new("arrow-left", class: "size-4 flex-none text-text-muted")
      span(class: "truncate text-sm font-medium text-text-secondary group-hover:text-text-primary") { t(".dashboard") }
    end
  end

  def nav_item(row)
    active = row.key == @active_key
    tone = active ? "bg-accent-soft font-semibold text-accent-soft-fg" : "text-text-secondary hover:bg-surface-card"
    a(
      href: plugin_config_path(@config.discord_id, row.key),
      aria_current: ("page" if active),
      class: "flex items-center gap-2.5 rounded-md px-2.5 py-2 transition-colors #{tone}"
    ) do
      item_tile(row, active)
      span(class: "flex-1 text-[13px]") { t("components.plugin_row.plugin.#{row.key}.name") }
      status_dot(row)
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
