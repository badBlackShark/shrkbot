# frozen_string_literal: true

class Components::TwilightStruggle::ConfigForm < Components::Base
  TEMPLATES = [:win, :tie, :video].freeze

  def initialize(tournament:, enable_error: nil)
    @tournament = tournament
    @enable_error = enable_error
  end

  def view_template
    div(id: "twilight_struggle-config", class: "flex flex-col gap-5", data: {controller: "twilight-struggle-preview", action: "input->twilight-struggle-preview#render"}) do
      enable_error_callout
      channel_card
      render Components::TwilightStruggle::PingCard.new(tournament: @tournament, inherited:)
      render Components::TwilightStruggle::TokenHelpCard.new
      TEMPLATES.each { |kind| template_card(kind) }
      archive_card
    end
  end

  private

  def enable_error_callout
    return unless @enable_error

    render Components::Callout.new(variant: :danger) { @enable_error }
  end

  def channel_card
    render Components::ChannelCard.new(
      name: "tournament[discord_channel_id]",
      channels:,
      selected: @tournament.discord_channel_id,
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
      value: @tournament.public_send(:"template_#{kind}").presence || inherited_template(kind),
      placeholder: inherited_template(kind),
      channel: channel_label
    )
  end

  def archive_card
    render Components::ToggleCard.new(
      name: "tournament[archived]",
      checked: @tournament.manually_archived?,
      label: t(".archive.label"),
      help: t(".archive.help")
    )
  end

  def channel_label
    label_for(@tournament.discord_channel_id) || inherited_channel_label
  end

  def inherited_channel_label
    @inherited_channel_label ||= label_for(inherited.channel_id)
  end

  def label_for(channel_id)
    return nil if channel_id.blank?

    name = channel_names[channel_id]
    "# #{name}" if name
  end

  def channel_names
    @channel_names ||= channel_options.labels_by_id
  end

  def channels
    @channels ||= channel_options.options
  end

  def channel_options
    @channel_options ||= ChannelOptions.new(@tournament.server_configuration)
  end

  def inherited_template(kind)
    inherited.public_send(:"template_#{kind}")
  end

  def inherited
    @inherited ||= ::TwilightStruggle::EffectiveConfig.new(@tournament.parent)
  end
end
