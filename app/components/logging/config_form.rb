class Components::Logging::ConfigForm < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(server_configuration:, enabled:, enable_error: nil)
    @config = server_configuration
    @settings = server_configuration.logging_setting
    @enabled = enabled
    @enable_error = enable_error
  end

  def view_template
    div(id: "logging-config") do
      form_with(url: server_logging_path(@config.discord_id), method: :patch, class: "flex flex-col gap-5", data: {controller: "enable-gate"}) do
        enable_card
        channel_card
        events_card
        save_bar
      end
    end
  end

  private

  def enable_card
    render Components::Card.new do
      div(class: "flex items-center justify-between gap-4") do
        div do
          p(class: "font-semibold") { t(".enable.label") }
          p(class: "mt-0.5 text-sm text-text-secondary") { t(".enable.help") }
        end
        render Components::Toggle.new(
          name: "logging[enabled]",
          checked: @enabled,
          label: t(".enable.label"),
          data: {enable_gate_target: "toggle", action: "change->enable-gate#update"}
        )
      end
      field_error(@enable_error)
    end
  end

  def channel_card
    render Components::Card.new do
      label(class: "block text-sm font-semibold") { t(".channel.label") }
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
    render Components::Card.new do
      p(class: "text-sm font-semibold") { t(".events.label") }
      p(class: "mb-3 mt-0.5 text-sm text-text-secondary") { t(".events.help") }
      render Components::EnableGate.new(enabled: @enabled, message: t(".events.gated")) do
        div(class: "flex flex-col gap-5") do
          LoggableEventCatalog.grouped_by_plugin.each do |plugin, definitions|
            event_group(plugin, definitions)
          end
        end
      end
    end
  end

  def event_group(plugin, definitions)
    div do
      p(class: "mb-2 text-[11px] font-semibold uppercase tracking-widest text-text-secondary") { t(".events.plugin.#{plugin}") }
      div(class: "flex flex-col gap-2") do
        definitions.each { |definition| event_row(definition) }
      end
    end
  end

  def event_row(definition)
    name = t(".events.event.#{definition.plugin}.#{definition.event}")
    div(class: "flex items-center justify-between gap-4 rounded-md border border-border-default px-3 py-2") do
      span(class: "text-sm") { name }
      render Components::Toggle.new(
        name: "logging[actions][#{definition.key}]",
        checked: @settings.action_enabled?(definition.key),
        label: name
      )
    end
  end

  def visibility_warning
    return unless visible_channel?

    render Components::Callout.new(variant: :warning, class: "mt-3") do
      plain t(".channel.visible_warning")
    end
  end

  def save_bar
    div(class: "flex justify-end") do
      render Components::Button.new(variant: :primary, size: :lg, type: "submit", icon: "check", label: t(".save"))
    end
  end

  def field_error(message)
    return unless message

    p(class: "mt-3 flex items-center gap-1.5 text-sm text-danger") do
      render Components::Icon.new("warning", class: "size-4 flex-none")
      span { message }
    end
  end

  def visible_channel?
    return false unless @settings.channel_id

    @config.server_channels.find_by(discord_id: @settings.channel_id)&.everyone_visible?
  end

  def channels
    @channels ||= @config.server_channels.text.map do |channel|
      Components::TomSelect::Option.for(value: channel.discord_id, label: "# #{channel.name}")
    end
  end
end
