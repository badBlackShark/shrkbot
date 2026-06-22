# frozen_string_literal: true

class Components::PluginRow < Components::Base
  ICONS = {roles: "users", welcomes: "hand-raised", logging: "document-text", reminders: "clock"}.freeze

  def initialize(server_id:, key:, enabled:, configured:, locked: false)
    @server_id = server_id
    @key = key
    @enabled = enabled
    @configured = configured
    @locked = locked
  end

  def view_template
    border = @enabled ? "border-brand-200" : "border-ink-200"
    div(id: "plugin-#{@key}", class: "flex items-center gap-4 rounded-lg border #{border} bg-ink-0 p-5 shadow-sm") do
      icon
      div(class: "min-w-0 flex-1") do
        div(class: "flex flex-wrap items-center gap-2") do
          span(class: "font-display font-semibold") { t(".plugin.#{@key}.name") }
          status_badge
        end
        p(class: "mt-0.5 text-sm text-ink-600") { t(".plugin.#{@key}.description") }
      end
      configure_link
      toggle
    end
  end

  private

  def toggle
    name = t(".plugin.#{@key}.name")
    if @locked
      render Components::Tooltip.new(text: t(".plugin.#{@key}.locked")) do
        render Components::Toggle.new(name: :enabled, checked: true, label: t(".toggle", plugin: name), disabled: true)
      end
    else
      render Components::Toggle.new(
        name: :enabled,
        checked: @enabled,
        label: t(".toggle", plugin: name),
        url: toggle_plugin_server_path(@server_id, @key),
        submit_on_change: true
      )
    end
  end

  def icon
    tone = @enabled ? "bg-brand-500 text-white" : "bg-ink-100 text-ink-400"
    span(class: "flex size-11 flex-none items-center justify-center rounded-md #{tone}") do
      render Components::Icon.new(ICONS[@key], class: "size-5")
    end
  end

  def status_badge
    state, tone, dot =
      if @locked
        [:always_enabled, "bg-success-soft text-success", "bg-success"]
      elsif !@enabled
        [:inactive, "bg-ink-100 text-ink-600", "bg-ink-400"]
      elsif @configured
        [:enabled, "bg-success-soft text-success", "bg-success"]
      else
        [:needs_setup, "bg-warning-soft text-warning", "bg-warning"]
      end

    span(class: "inline-flex items-center gap-1.5 rounded-full px-2 py-0.5 text-xs font-semibold #{tone}") do
      span(class: "size-1.5 rounded-full #{dot}")
      plain t(".status.#{state}")
    end
  end

  def configure_link
    a(
      href: "#",
      class: "btn-fill btn-fill-ghost inline-flex h-9 flex-none items-center gap-1.5 rounded-md border border-ink-200 px-3.5 text-sm font-semibold transition-colors hover:bg-ink-50"
    ) do
      span { t(".configure") }
      render Components::Icon.new("arrow-right", class: "size-4")
    end
  end
end
