# frozen_string_literal: true

class Components::SubPluginRow < Components::Base
  include Components::PluginNav

  def self.toggle_form_id(key)
    "#{key}-overview-toggle-form"
  end

  def initialize(server_configuration:, row:)
    @config = server_configuration
    @row = row
  end

  def view_template
    render Components::Card.new(enabled: @row.enabled, class: "flex items-center gap-4") do
      render Components::PluginTile.new(icon: plugin_icon(@row.key), enabled: @row.enabled)
      div(class: "min-w-0 flex-1") do
        div(class: "flex flex-wrap items-center gap-2") do
          span(class: "font-display font-semibold") { @row.name }
          status_badge
          render Components::PluginBadges.new(key: @row.key)
        end
        render Components::Description.new { @row.description }
      end
      configure_link
      toggle_control
    end
  end

  private

  def status_badge
    return if @row.configured

    render Components::Badge.new(variant: :warning, dot: true) { t(".status.needs_setup") }
  end

  def needs_setup?
    !@row.configured && !@row.enabled
  end

  def configure_link
    render Components::Button.new(
      variant: :secondary,
      href: sub_path,
      label: t(".configure"),
      trailing_icon: "arrow-right",
      class: "flex-none"
    )
  end

  def sub_path
    PluginPaths.for(@config, @row.key)
  end

  def toggle_control
    if @config.preview?
      locked_toggle(t("components.plugin_row.preview_locked"))
    elsif needs_setup?
      locked_toggle(t("components.plugin_row.needs_setup_hint"))
    else
      enabled_toggle
    end
  end

  def locked_toggle(reason)
    render Components::Tooltip.new(text: reason) do
      render Components::Toggle.new(
        name: :enabled,
        checked: @row.enabled,
        label: toggle_label,
        disabled: true
      )
    end
  end

  def enabled_toggle
    render Components::Toggle.new(
      name: :enabled,
      checked: @row.enabled,
      label: toggle_label,
      submit_on_change: true,
      form: self.class.toggle_form_id(@row.key)
    )
  end

  def toggle_label
    t(".toggle_label", name: @row.name)
  end
end
