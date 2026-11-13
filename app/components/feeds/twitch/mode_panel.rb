# frozen_string_literal: true

class Components::Feeds::Twitch::ModePanel < Components::Base
  def initialize(mode:, card:, hidden:, preview_label:)
    @mode = mode
    @card = card
    @hidden = hidden
    @preview_label = preview_label
  end

  def view_template
    div(class: "mt-3 flex flex-col gap-3", hidden: @hidden, data: {option_panels_target: "panel", value: @mode}) do
      render Components::DiscordMessagePreview.new(label: @preview_label, messages: [{card: @card}])
    end
  end
end
