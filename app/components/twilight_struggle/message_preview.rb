# frozen_string_literal: true

class Components::TwilightStruggle::MessagePreview < Components::Base
  KINDS = [:win, :tie, :video].freeze

  def initialize(channel:)
    @channel = channel
  end

  def view_template
    render Components::DiscordMessagePreview.new(
      label: t(".label"),
      channel: @channel,
      messages: KINDS.map { |kind| {timestamp: t(".#{kind}"), body_data: body_data(kind)} }
    )
  end

  private

  def body_data(kind)
    {
      twilight_struggle_preview_target: "#{kind}Output",
      empty_hint: t(".empty")
    }
  end
end
