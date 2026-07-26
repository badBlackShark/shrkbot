# frozen_string_literal: true

class Components::TwilightStruggle::ConfigForm < Components::Base
  TEMPLATES = [:win, :tie, :video].freeze

  def initialize(destination:)
    @destination = destination
  end

  def view_template
    div(id: "twilight_struggle-config", class: "flex flex-col gap-5", data: {controller: "twilight-struggle-preview", action: "input->twilight-struggle-preview#render"}) do
      channel_card
      render Components::TwilightStruggle::PingCard.new(destination: @destination, inherited:)
      render Components::TwilightStruggle::TokenHelpCard.new
      TEMPLATES.each { |kind| template_card(kind) }
      archive_card
    end
  end

  private

  def channel_card
    render Components::ChannelCard.new(
      name: "destination[discord_channel_id]",
      channels:,
      selected: @destination.discord_channel_id,
      label: t(".channel.label"),
      help: channel_help
    )
  end

  def channel_help
    return t(".channel.help_inherited", channel: inherited_channel_label) if inherited_channel_label

    t(".channel.help")
  end

  def template_card(kind)
    render Components::TwilightStruggle::TemplateCard.new(
      kind:,
      value: @destination.public_send(:"template_#{kind}").presence || inherited_template(kind),
      placeholder: inherited_template(kind),
      channel: channel_label
    )
  end

  def archive_card
    render Components::ToggleCard.new(
      name: "destination[archived]",
      checked: @destination.manually_archived?,
      label: t(".archive.label"),
      help: t(".archive.help")
    )
  end

  def channel_label
    channel_names[@destination.discord_channel_id] || channel_names[inherited.channel_id]
  end

  def inherited_channel_label
    @inherited_channel_label ||= qualified_channel_names[inherited.channel_id]
  end

  def channel_names
    @channel_names ||= channel_options.labels_by_id
  end

  def qualified_channel_names
    @qualified_channel_names ||= channel_options.qualified_labels_by_id
  end

  def channels
    @channels ||= channel_options.options
  end

  def channel_options
    @channel_options ||= ChannelOptions.new(@destination.server_configuration)
  end

  def inherited_template(kind)
    inherited.public_send(:"template_#{kind}")
  end

  def inherited
    @inherited ||= ::TwilightStruggle::EffectiveConfig.new(@destination.tournament.parent, @destination.server_configuration)
  end
end
