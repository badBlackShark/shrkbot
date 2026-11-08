# frozen_string_literal: true

class Servers::Twitch::SubscriptionsController < Servers::Feeds::SubscriptionsController
  private

  def plugin_key
    :twitch
  end

  def lookup_param
    :channel
  end

  def settings_params
    [*::Feeds::Twitch::Settings::ROLE_COLUMNS.values, :live_end_mode, :show_viewers]
  end

  def settings
    subscription_params.slice(*settings_params).to_h.symbolize_keys
  end
end
