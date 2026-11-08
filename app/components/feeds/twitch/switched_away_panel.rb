# frozen_string_literal: true

class Components::Feeds::Twitch::SwitchedAwayPanel < Components::Base
  def initialize(mode:, card:, hidden:)
    @mode = mode
    @card = card
    @hidden = hidden
  end

  def view_template
    div(class: "mt-3 flex flex-col gap-3", hidden: @hidden, data: {option_panels_target: "panel", value: @mode}) do
      render Components::FieldHelp.new { t(".#{@mode}") }
      render Components::DiscordMessagePreview.new(label: t(".preview"), messages: [{card: @card}]) if @card
    end
  end
end
