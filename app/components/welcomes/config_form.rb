# frozen_string_literal: true

class Components::Welcomes::ConfigForm < Components::Base
  FIELD = "w-full resize-none rounded-control border-[1.5px] border-border-strong bg-surface-card px-3 py-2 " \
    "text-sm text-text-primary placeholder:text-text-secondary focus:border-accent focus:outline-none " \
    "focus:ring-3 focus:ring-[var(--focus-ring)]"
  PLACEHOLDERS = %w[user username displayname membercount].freeze

  def initialize(server_configuration:, enable_error: nil)
    @config = server_configuration
    @settings = server_configuration.welcome_settings
    @enable_error = enable_error
  end

  def view_template
    render Components::ConfigSections.new(key: "welcomes", enable_error: @enable_error, data: {controller: "welcome-preview"}) do
      channel_card
      message_card
      preview
    end
  end

  private

  def channel_card
    render Components::ChannelCard.new(
      name: "welcomes[channel_id]",
      channels:,
      selected: @settings.channel_id,
      label: t(".channel.label"),
      help: t(".channel.help"),
      required: true
    )
  end

  def message_card
    render Components::Card.new(padding: :none) do
      div(class: "flex divide-x divide-border-subtle py-5") do
        message_column(:join) do
          ping_toggle
        end
        message_column(:leave) do
          suppress_removal_toggle
        end
      end
      placeholder_help
    end
  end

  def message_column(kind)
    div(class: "flex min-w-0 flex-1 flex-col gap-4 px-5") do
      message_group(kind)
      yield
    end
  end

  def message_group(kind)
    div(class: "flex flex-col gap-2") do
      message_heading(kind)
      message_field(kind)
      info_line(kind)
    end
  end

  def message_heading(kind)
    div(class: "flex min-h-8 items-center justify-between gap-3") do
      div do
        label(for: field_id(kind), class: "block text-sm font-semibold") { t(".#{kind}_message.label") }
        p(class: "mt-0.5 text-sm text-text-secondary") { t(".#{kind}_message.help") }
      end
      reset_button(kind)
    end
  end

  def reset_button(kind)
    span(
      class: "flex",
      hidden: message(kind) == default_message(kind),
      data: {welcome_preview_target: "#{kind}Reset"}
    ) do
      render Components::ResetButton.new(
        label: t(".reset_to_default"),
        data: {action: "welcome-preview#reset", welcome_preview_kind_param: kind}
      )
    end
  end

  def message_field(kind)
    textarea(
      name: "welcomes[#{kind}_message]",
      id: field_id(kind),
      rows: 4,
      class: FIELD,
      placeholder: t(".empty"),
      data: {
        welcome_preview_target: "#{kind}Message",
        action: "input->welcome-preview#render",
        default: default_message(kind)
      }
    ) { message(kind) }
  end

  def info_line(kind)
    p(class: "flex items-start gap-1 text-xs text-text-secondary") do
      render Components::Icon.new("info", class: "mt-0.5 size-3 flex-none text-accent")
      span do
        code(class: "font-mono") { "{user}" }
        whitespace
        plain t(".#{kind}_message.info")
      end
    end
  end

  def ping_toggle
    render Components::ToggleRow.new(
      name: "welcomes[ping_on_join]",
      checked: @settings.ping_on_join,
      label: t(".ping_on_join.label"),
      help: t(".ping_on_join.help")
    )
  end

  def suppress_removal_toggle
    render Components::ToggleRow.new(
      name: "welcomes[suppress_removal_messages]",
      checked: @settings.suppress_removal_messages,
      label: t(".suppress_removal_messages.label")
    )
  end

  def placeholder_help
    div(class: "border-t border-border-subtle px-5 pb-5 pt-4") do
      render Components::PlaceholderSection.new do
        render Components::PlaceholderChips.new(tokens: placeholders)
      end
    end
  end

  def placeholders
    PLACEHOLDERS.index_with { |name| t(".placeholders.#{name}") }
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

  def message(kind)
    @settings.public_send(:"#{kind}_message")
  end

  def default_message(kind)
    ::Welcomes::Settings.column_defaults.fetch("#{kind}_message")
  end

  def field_id(kind)
    "welcomes_#{kind}_message"
  end

  def preview_body_data(kind)
    {welcome_preview_target: "#{kind}Output", empty_hint: t(".empty")}
  end

  def preview_channel
    return unless @settings.channel_id

    channel_options.labels_by_id[@settings.channel_id]
  end

  def channels
    @channels ||= channel_options.options
  end

  def channel_options
    @channel_options ||= ChannelOptions.new(@config)
  end
end
