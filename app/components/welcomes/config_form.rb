# frozen_string_literal: true

class Components::Welcomes::ConfigForm < Components::Base
  FIELD = "w-full resize-none rounded-control border-[1.5px] border-border-strong bg-surface-card px-3 py-2 " \
    "text-sm text-text-primary placeholder:text-text-secondary focus:border-accent focus:outline-none " \
    "focus:ring-3 focus:ring-[var(--focus-ring)]"

  def initialize(server_configuration:, enable_error: nil)
    @config = server_configuration
    @settings = server_configuration.welcome_settings
    @enable_error = enable_error
  end

  def view_template
    div(id: "welcomes-config", class: "flex flex-col gap-5", data: {controller: "welcome-preview"}) do
      enable_error_callout
      channel_card
      message_cards
      placeholder_help
      preview
    end
  end

  private

  def enable_error_callout
    return unless @enable_error

    render Components::Callout.new(variant: :danger) { @enable_error }
  end

  def channel_card
    render Components::Card.new do
      label(class: "block text-sm font-semibold") do
        plain t(".channel.label")
        required_marker
      end
      p(class: "mb-2 mt-0.5 text-sm text-text-secondary") { t(".channel.help") }
      if channels.empty?
        p(class: "text-sm text-text-secondary") { t(".channel.none") }
      else
        render Components::TomSelect.new(
          name: "welcomes[channel_id]",
          options: channels,
          selected: @settings.channel_id,
          placeholder: t(".channel.placeholder"),
          include_blank: true
        )
      end
    end
  end

  def message_cards
    div(class: "grid gap-5 sm:grid-cols-2") do
      message_card(:join_message, @settings.join_message)
      message_card(:leave_message, @settings.leave_message)
    end
  end

  def message_card(name, value)
    render Components::Card.new do
      label(class: "block text-sm font-semibold") { t(".#{name}.label") }
      p(class: "mb-2 mt-0.5 text-sm text-text-secondary") { t(".#{name}.help") }
      textarea(
        name: "welcomes[#{name}]",
        rows: 3,
        class: FIELD,
        placeholder: t(".#{name}.placeholder"),
        data: {welcome_preview_target: camel(name), action: "input->welcome-preview#render"}
      ) { value }
      info_line(name)
    end
  end

  def info_line(name)
    p(class: "mt-1.5 flex items-start gap-1 text-xs text-text-secondary") do
      render Components::Icon.new("info", class: "mt-0.5 size-3 flex-none text-accent")
      span do
        code(class: "font-mono") { "{user}" }
        whitespace
        plain t(".#{name}.info")
      end
    end
  end

  def placeholder_help
    render Components::Callout.new(variant: :neutral) do
      span(class: "font-semibold") { t(".placeholders.intro") }
      whitespace
      placeholder_chip("{user}", t(".placeholders.user"))
      whitespace
      placeholder_chip("{membercount}", t(".placeholders.membercount"))
    end
  end

  def placeholder_chip(token, description)
    render Components::Tooltip.new(text: description) do
      code(
        tabindex: "0",
        class: "cursor-help rounded bg-surface-sunken px-1.5 py-0.5 font-mono text-xs text-accent-soft-fg " \
          "focus:outline-none focus-visible:ring-2 focus-visible:ring-[var(--focus-ring)]"
      ) { token }
    end
  end

  def preview
    render Components::DiscordMessagePreview.new(
      label: t(".preview.label"),
      channel: preview_channel,
      messages: [
        {timestamp: t(".preview.timestamp"), body_data: preview_body_data(:join)},
        {body_data: preview_body_data(:leave)}
      ]
    )
  end

  def preview_body_data(kind)
    {welcome_preview_target: "#{kind}Output", empty_hint: t(".preview.empty")}
  end

  def required_marker
    span(class: "ml-1 text-xs font-semibold text-danger", title: t(".channel.required")) { "*" }
  end

  def preview_channel
    return unless @settings.channel_id

    name = @config.server_channels.find_by(discord_id: @settings.channel_id)&.name
    "# #{name}" if name
  end

  def channels
    @channels ||= @config.server_channels.text.map do |channel|
      Components::TomSelect::Option.for(value: channel.discord_id, label: "# #{channel.name}")
    end
  end

  def camel(name)
    name.to_s.camelize(:lower)
  end
end
