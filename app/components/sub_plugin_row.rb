# frozen_string_literal: true

class Components::SubPluginRow < Components::Base
  include Components::PluginNav

  STATUS_VARIANTS = {
    enabled: :success,
    needs_setup: :warning,
    disabled: :neutral
  }.freeze

  def self.toggle_form_id(key)
    "#{key}-overview-toggle-form"
  end

  def initialize(server_configuration:, row:, group_enabled:)
    @config = server_configuration
    @row = row
    @group_enabled = group_enabled
  end

  def view_template
    render Components::Card.new(enabled: @row.enabled, class: "flex items-center gap-4") do
      render Components::PluginTile.new(icon: plugin_icon(@row.key), enabled: @row.enabled)
      div(class: "min-w-0 flex-1") do
        div(class: "flex flex-wrap items-center gap-2") do
          span(class: "font-display font-semibold") { @row.name }
          status_badge
        end
        p(class: "mt-0.5 text-sm text-text-secondary") { @row.description }
        needs_setup_inline_warning if needs_setup?
      end
      configure_link
      toggle_control
    end
  end

  private

  def status_badge
    render Components::Badge.new(variant: STATUS_VARIANTS.fetch(status), dot: true) do
      t(".status.#{status}")
    end
  end

  def status
    return :needs_setup unless @row.configured
    @row.enabled ? :enabled : :disabled
  end

  def needs_setup?
    !@row.configured && @group_enabled
  end

  def needs_setup_inline_warning
    p(class: "mt-1 flex items-center gap-1 text-xs font-medium text-warning") do
      render Components::Icon.new("warning", class: "size-3.5")
      span { t(".needs_setup_hint.#{@row.key}") }
    end
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
    if needs_setup?
      locked_toggle
    else
      enabled_toggle
    end
  end

  def locked_toggle
    render Components::Tooltip.new(text: t(".locked_reason.#{@row.key}")) do
      render Components::Toggle.new(
        name: "#{@row.key}[enabled]",
        checked: @row.enabled,
        label: t(".toggle_label", name: @row.name),
        disabled: true
      )
    end
  end

  def enabled_toggle
    input(
      type: "hidden",
      name: "from_overview",
      value: "1",
      form: stub_form_id
    )
    toggle_hidden_fields
    render Components::Toggle.new(
      name: "#{@row.key}[enabled]",
      checked: @row.enabled,
      label: t(".toggle_label", name: @row.name),
      submit_on_change: true,
      form: stub_form_id
    )
  end

  def toggle_hidden_fields
    @row.toggle_fields.each do |name, value|
      (value.is_a?(Array) ? value : [value]).each { |item| input(type: "hidden", name:, value: item, form: stub_form_id) }
    end
  end

  def stub_form_id
    self.class.toggle_form_id(@row.key)
  end
end
