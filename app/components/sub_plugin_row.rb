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

  def initialize(server_configuration:, key:, name:, description:, enabled:, configured:, toggle_fields:, group_enabled:)
    @config = server_configuration
    @key = key
    @name = name
    @description = description
    @enabled = enabled
    @configured = configured
    @toggle_fields = toggle_fields
    @group_enabled = group_enabled
  end

  def view_template
    render Components::Card.new(enabled: @enabled, class: "flex items-center gap-4") do
      render Components::PluginTile.new(icon: plugin_icon(@key), enabled: @enabled)
      div(class: "min-w-0 flex-1") do
        div(class: "flex flex-wrap items-center gap-2") do
          span(class: "font-display font-semibold") { @name }
          status_badge
        end
        p(class: "mt-0.5 text-sm text-text-secondary") { @description }
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
    return :needs_setup unless @configured
    @enabled ? :enabled : :disabled
  end

  def needs_setup?
    !@configured && @group_enabled
  end

  def needs_setup_inline_warning
    p(class: "mt-1 flex items-center gap-1 text-xs font-medium text-warning") do
      render Components::Icon.new("warning", class: "size-3.5")
      span { t(".needs_setup_hint.#{parent}") }
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
    PluginPaths.for(@config, @key)
  end

  def toggle_control
    if needs_setup?
      locked_toggle
    else
      enabled_toggle
    end
  end

  def locked_toggle
    render Components::Tooltip.new(text: t(".locked_reason.#{parent}")) do
      render Components::Toggle.new(
        name: "#{@key}[enabled]",
        checked: @enabled,
        label: t(".toggle_label", name: @name),
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
      name: "#{@key}[enabled]",
      checked: @enabled,
      label: t(".toggle_label", name: @name),
      submit_on_change: true,
      form: stub_form_id
    )
  end

  def toggle_hidden_fields
    @toggle_fields.each do |name, value|
      Array(value).each { |item| input(type: "hidden", name:, value: item, form: stub_form_id) }
    end
  end

  def parent
    PluginCatalog.find(@key).parent
  end

  def stub_form_id
    self.class.toggle_form_id(@key)
  end
end
