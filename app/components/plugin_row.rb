# frozen_string_literal: true

class Components::PluginRow < Components::Base
  include Components::PluginNav

  STATUS_VARIANTS = {
    enabled: :success,
    needs_setup: :warning,
    disabled: :neutral
  }.freeze

  def initialize(server_id:, row:)
    @server_id = server_id
    @row = row
  end

  def view_template
    render Components::Card.new(enabled: @row.enabled, id: "plugin-#{@row.key}", class: "flex min-h-[108px] flex-wrap items-center gap-x-4 gap-y-3") do
      identity
      div(class: "ml-auto flex flex-none items-center gap-3") do
        configure_link
        toggle
      end
    end
  end

  private

  def identity
    div(class: "flex min-w-0 flex-[1_1_320px] items-center gap-4") do
      render Components::PluginTile.new(icon: plugin_icon(@row.key), enabled: @row.enabled)
      div(class: "min-w-0 flex-1") do
        div(class: "flex flex-wrap items-center gap-2") do
          span(class: "font-display font-semibold") { name }
          status_badge
          bespoke_badge if @row.bespoke
        end
        p(class: "mt-0.5 text-sm leading-[1.5] text-pretty text-text-secondary") { t(".plugin.#{@row.key}.description") }
      end
    end
  end

  def toggle
    if !@row.manageable
      locked_toggle(checked: @row.enabled, tooltip: t(".not_manageable"))
    elsif @row.locked
      locked_toggle(checked: true, tooltip: t(".plugin.#{@row.key}.locked"))
    elsif !@row.toggleable
      locked_toggle(checked: @row.enabled, tooltip: t(".admin_only"))
    elsif blocked_until_setup?
      locked_toggle(checked: false, tooltip: t(".needs_setup_hint"))
    else
      render Components::Toggle.new(
        name: :enabled,
        checked: @row.enabled,
        label: t(".toggle", plugin: name),
        url: server_plugin_path(@server_id, @row.key),
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
    !@row.configured && !@row.enabled
  end

  def name
    t(".plugin.#{@row.key}.name")
  end

  def status_badge
    if @row.locked
      render Components::Badge.new(variant: :copper) { t(".status.global") }
    else
      render Components::Badge.new(variant: STATUS_VARIANTS.fetch(status), dot: true) { t(".status.#{status}") }
    end
  end

  def bespoke_badge
    render Components::Badge.new(variant: :copper) do
      render Components::Icon.new("puzzle-piece", weight: :fill, class: "size-3.5")
      plain t(".bespoke")
    end
  end

  def status
    return :needs_setup unless @row.configured
    @row.enabled ? :enabled : :disabled
  end

  def configure_link
    return configure_button if @row.manageable

    render Components::Tooltip.new(text: t(".not_manageable")) do
      configure_button
    end
  end

  def configure_button
    render Components::Button.new(
      variant: :secondary,
      href: @row.manageable ? configure_href : nil,
      label: t(".configure"),
      trailing_icon: "arrow-right",
      disabled: !@row.manageable,
      class: "flex-none"
    )
  end

  def configure_href
    plugin_config_path(@server_id, @row.key) || "#"
  end
end
