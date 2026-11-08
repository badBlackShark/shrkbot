# frozen_string_literal: true

class Components::Feeds::Twitch::EndModeField < Components::Feeds::Twitch::ModeField
  private

  def setting
    :live_end_mode
  end

  def modes
    ::Feeds::Twitch::Settings::LIVE_END_MODES
  end

  def panel_class
    Components::Feeds::Twitch::EndModePanel
  end

  def card(mode)
    samples.end_mode_card(mode)
  end

  def label
    t(".label")
  end

  def mode_label(mode)
    t(".modes.#{mode}")
  end
end
