# frozen_string_literal: true

class Servers::Steam::SubscriptionsController < Servers::Feeds::SubscriptionsController
  private

  def plugin_key
    :steam
  end

  def lookup_param
    :app
  end

  def settings_params
    [:role_id, :body_length, {languages: []}]
  end

  def settings
    {role_id: subscription_params[:role_id], body_length: subscription_params[:body_length], languages:}
  end

  def languages
    Array(subscription_params[:languages])
  end

  def role_ids
    [subscription_params[:role_id]]
  end
end
