# frozen_string_literal: true

class Components::PluginRow < Components::Base
  ICONS = {roles: "users-three", welcomes: "hand-waving", logging: "scroll", reminders: "bell-ringing"}.freeze

  STATUS_VARIANTS = {
    always_enabled: :success,
    enabled: :success,
    needs_setup: :warning,
    disabled: :neutral
  }.freeze

  def initialize(server_id:, key:, enabled:, configured:, locked: false)
    @server_id = server_id
    @key = key
    @enabled = enabled
    @configured = configured
    @locked = locked
  end

  def view_template
    render Components::Card.new(enabled: @enabled, id: "plugin-#{@key}", class: "flex items-center gap-4") do
      render Components::PluginTile.new(icon: ICONS[@key], enabled: @enabled)
      div(class: "min-w-0 flex-1") do
        div(class: "flex flex-wrap items-center gap-2") do
          span(class: "font-display font-semibold") { name }
          status_badge
        end
        p(class: "mt-0.5 text-sm text-text-secondary") { t(".plugin.#{@key}.description") }
      end
      configure_link
      toggle
    end
  end

  private

  def toggle
    if @locked
      locked_toggle(checked: true, tooltip: t(".plugin.#{@key}.locked"))
    elsif blocked_until_setup?
      locked_toggle(checked: false, tooltip: t(".needs_setup_hint"))
    else
      render Components::Toggle.new(
        name: :enabled,
        checked: @enabled,
        label: t(".toggle", plugin: name),
        url: server_plugin_path(@server_id, @key),
        submit_on_change: true
      )
    end
  end

  def locked_toggle(checked:, tooltip:)
    render Components::Tooltip.new(text: tooltip) do
      render Components::Toggle.new(name: :enabled, checked:, label: t(".toggle", plugin: name), disabled: true)
    end
  end

  def blocked_until_setup?
    !@configured && !@enabled
  end

  def name
    t(".plugin.#{@key}.name")
  end

  def status_badge
    render Components::Badge.new(variant: STATUS_VARIANTS.fetch(status), dot: true) { t(".status.#{status}") }
  end

  def status
    return :always_enabled if @locked
    return :needs_setup unless @configured
    @enabled ? :enabled : :disabled
  end

  def configure_link
    render Components::Button.new(
      variant: :secondary,
      href: configure_href,
      label: t(".configure"),
      trailing_icon: "arrow-right",
      class: "flex-none"
    )
  end

  def configure_href
    case @key.to_sym
    when :welcomes then server_welcomes_path(@server_id)
    when :logging then server_logging_path(@server_id)
    else "#"
    end
  end
end
