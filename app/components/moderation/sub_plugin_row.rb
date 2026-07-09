# frozen_string_literal: true

class Components::Moderation::SubPluginRow < Components::Base
  include Components::PluginNav

  STATUS_VARIANTS = {
    enabled: :success,
    needs_setup: :warning,
    disabled: :neutral
  }.freeze

  ICONS = {
    spam_protection: "megaphone-slash",
    image_scanning: "scan"
  }.freeze

  def initialize(server_id:, key:, name:, description:, enabled:, configured:, settings:, group_enabled:)
    @server_id = server_id
    @key = key
    @name = name
    @description = description
    @enabled = enabled
    @configured = configured
    @settings = settings
    @group_enabled = group_enabled
  end

  def view_template
    render Components::Card.new(enabled: @enabled, class: "flex items-center gap-4") do
      render Components::PluginTile.new(icon: ICONS.fetch(@key), enabled: @enabled)
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
      span { t(".needs_setup_hint") }
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
    plugin_config_path(@server_id, @key)
  end

  def toggle_control
    if needs_setup?
      locked_toggle
    else
      enabled_toggle
    end
  end

  def locked_toggle
    render Components::Tooltip.new(text: t(".locked_reason")) do
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
    settings_hidden_fields
    render Components::Toggle.new(
      name: "#{@key}[enabled]",
      checked: @enabled,
      label: t(".toggle_label", name: @name),
      submit_on_change: true,
      form: stub_form_id
    )
  end

  def settings_hidden_fields
    return unless @settings

    (@key == :spam_protection) ? spam_protection_hidden_fields : image_scanning_hidden_fields
  end

  def spam_protection_hidden_fields
    input(type: "hidden", name: "spam_protection[channel_threshold]", value: @settings.channel_threshold, form: stub_form_id)
    input(type: "hidden", name: "spam_protection[window_seconds]", value: @settings.window_seconds, form: stub_form_id)
    input(type: "hidden", name: "spam_protection[similarity]", value: @settings.similarity, form: stub_form_id)
    input(type: "hidden", name: "spam_protection[match_symbol_only_messages]", value: @settings.match_symbol_only_messages ? "1" : "0", form: stub_form_id)
    input(type: "hidden", name: "spam_protection[action]", value: @settings.action, form: stub_form_id)
    input(type: "hidden", name: "spam_protection[punishment]", value: @settings.punishment, form: stub_form_id)
    input(type: "hidden", name: "spam_protection[timeout_seconds]", value: @settings.timeout_seconds, form: stub_form_id)
  end

  def image_scanning_hidden_fields
    input(type: "hidden", name: "image_scanning[sensitivity]", value: @settings.sensitivity, form: stub_form_id)
    input(type: "hidden", name: "image_scanning[action]", value: @settings.action, form: stub_form_id)
    input(type: "hidden", name: "image_scanning[punishment]", value: @settings.punishment, form: stub_form_id)
    input(type: "hidden", name: "image_scanning[timeout_seconds]", value: @settings.timeout_seconds, form: stub_form_id)
    input(type: "hidden", name: "image_scanning[custom_keyword_min_hits]", value: @settings.custom_keyword_min_hits, form: stub_form_id)
    @settings.custom_keywords.each do |keyword|
      input(type: "hidden", name: "image_scanning[custom_keywords][]", value: keyword, form: stub_form_id)
    end
  end

  def stub_form_id
    "#{@key}-overview-toggle-form"
  end
end
