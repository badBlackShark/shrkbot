# frozen_string_literal: true

class Components::Feeds::Twitch::EndModeField < Components::Feeds::Twitch::ModeField
  private

  def setting
    :live_end_mode
  end

  def modes
    ::Feeds::Twitch::Settings::LIVE_END_MODES
  end

  def card(mode)
    samples.end_mode_card(mode)
  end
end
