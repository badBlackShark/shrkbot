# frozen_string_literal: true

class Components::Welcomes::ConfigForm < Components::Base
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
        %i[join leave].each do |kind|
          render Components::Welcomes::MessageColumn.new(kind:, settings: @settings) do
            send(:"#{kind}_toggle")
          end
        end
      end
      placeholder_help
    end
  end

  def join_toggle
    render Components::ToggleRow.new(
      name: "welcomes[ping_on_join]",
      checked: @settings.ping_on_join,
      label: t(".ping_on_join.label"),
      help: t(".ping_on_join.help")
    )
  end

  def leave_toggle
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
