# frozen_string_literal: true

class Components::Logging::ConfigForm < Components::Base
  def initialize(server_configuration:, enable_error: nil)
    @config = server_configuration
    @settings = server_configuration.logging_setting
    @enable_error = enable_error
  end

  def view_template
    div(id: "logging-config", class: "flex flex-col gap-5") do
      enable_error_callout
      channel_card
      events_card
    end
  end

  private

  def enable_error_callout
    return unless @enable_error

    render Components::Callout.new(variant: :danger) { @enable_error }
  end

  def channel_card
    render Components::Card.new(
      data: {
        controller: "channel-warning",
        action: "change->channel-warning#update",
        channel_warning_visible_ids_value: visible_channel_ids.to_json
      }
    ) do
      label(class: "block text-sm font-semibold") do
        plain t(".channel.label")
        required_marker
      end
      p(class: "mb-2 mt-0.5 text-sm text-text-secondary") { t(".channel.help") }
      if channels.empty?
        p(class: "text-sm text-text-secondary") { t(".channel.none") }
      else
        render Components::TomSelect.new(
          name: "logging[channel_id]",
          options: channels,
          selected: @settings.channel_id,
          placeholder: t(".channel.placeholder"),
          include_blank: true
        )
      end
      visibility_warning
    end
  end

  def events_card
    render Components::Card.new(padding: :none, class: "overflow-hidden") do
      div(class: "border-b border-border-subtle px-5 py-4") do
        p(class: "text-sm font-semibold") { t(".events.label") }
        p(class: "mt-0.5 text-sm text-text-secondary") { t(".events.help") }
      end
      LoggableEventCatalog.grouped_by_plugin.each do |plugin, definitions|
        event_group(plugin, definitions)
      end
    end
  end

  def event_group(plugin, definitions)
    enabled = definitions.count { |definition| @settings.action_enabled?(definition.key) }
    div(class: "relative border-b border-border-subtle last:border-b-0", data: {controller: "event-group"}) do
      details(
        open: true,
        data: {controller: "dropdown", dropdown_dismiss_on_outside_value: false}
      ) do
        summary(
          class: "flex h-11 cursor-pointer list-none select-none items-center gap-3 bg-surface-sunken px-5 pr-36 [&::-webkit-details-marker]:hidden",
          data: {action: "click->dropdown#toggle"}
        ) do
          render Components::Icon.new("caret-down", class: "dropdown-chevron size-4 flex-none text-text-muted")
          span(class: "text-[11px] font-semibold uppercase tracking-widest text-text-secondary") { t(".events.plugin.#{plugin}") }
          event_count(enabled, definitions.size)
        end
        div(class: "dropdown-menu divide-y divide-border-subtle", data: {dropdown_target: "menu"}) do
          definitions.each { |definition| event_row(definition) }
        end
      end
      toggle_all(plugin, enabled == definitions.size)
    end
  end

  def event_count(enabled, total)
    span(class: "ml-auto whitespace-nowrap text-xs text-text-muted") do
      span(data: {event_group_target: "count"}) { "#{enabled}/#{total}" }
      whitespace
      plain t(".events.enabled_count")
    end
  end

  def toggle_all(plugin, all_enabled)
    label_text = t(".events.toggle_all_label", plugin: t(".events.plugin.#{plugin}"))
    div(class: "absolute end-5 top-0 flex h-11 items-center gap-2") do
      span(class: "text-xs text-text-muted") { t(".events.toggle_all") }
      render Components::Toggle.new(
        checked: all_enabled,
        label: label_text,
        size: :mini,
        data: {event_group_target: "all", action: "change->event-group#toggleAll"}
      )
    end
  end

  def event_row(definition)
    name = t(".events.event.#{definition.plugin}.#{definition.event}")
    div(class: "flex items-center justify-between gap-4 px-5 py-3.5") do
      span(class: "text-sm font-medium") { name }
      render Components::Toggle.new(
        name: "logging[actions][#{definition.key}]",
        checked: @settings.action_enabled?(definition.key),
        label: name,
        data: {event_group_target: "event", action: "change->event-group#sync"}
      )
    end
  end

  def visibility_warning
    render Components::Callout.new(
      variant: :warning,
      class: "mt-3 #{"hidden" unless visible_channel?}",
      data: {channel_warning_target: "warning"}
    ) do
      plain t(".channel.visible_warning")
    end
  end

  def required_marker
    span(class: "ml-1 text-xs font-semibold text-danger", title: t(".channel.required")) { "*" }
  end

  def visible_channel?
    return false unless @settings.channel_id

    @config.server_channels.find_by(discord_id: @settings.channel_id)&.everyone_visible?
  end

  def visible_channel_ids
    @config.server_channels.text.select(&:everyone_visible?).map { |channel| channel.discord_id.to_s }
  end

  def channels
    @channels ||= @config.server_channels.text.map do |channel|
      Components::TomSelect::Option.for(value: channel.discord_id, label: "# #{channel.name}")
    end
  end
end
