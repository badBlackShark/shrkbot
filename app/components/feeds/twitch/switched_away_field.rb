# frozen_string_literal: true

class Components::Feeds::Twitch::SwitchedAwayField < Components::Feeds::Twitch::ModeField
  private

  def setting
    :switched_away
  end

  def modes
    ::Feeds::Twitch::Settings::SWITCHED_AWAY_MODES
  end

  def panel_class
    Components::Feeds::Twitch::SwitchedAwayPanel
  end

  def card(mode)
    samples.switched_card if mode == "summary"
  end

  def label
    t(".label")
  end

  def mode_label(mode)
    t(".modes.#{mode}")
  end
end
