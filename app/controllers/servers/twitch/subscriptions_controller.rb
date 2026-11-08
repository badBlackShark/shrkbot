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
    [*scalar_settings, {categories: []}]
  end

  def settings
    subscription_params.slice(*scalar_settings).to_h.symbolize_keys.merge(categories: ::Feeds::Twitch::CategoryValue.parse_all(subscription_params[:categories]))
  end

  def scalar_settings
    [*::Feeds::Twitch::Settings::ROLE_COLUMNS.values, :live_end_mode, :show_viewers, :switched_away]
  end
end
