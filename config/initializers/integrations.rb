# frozen_string_literal: true

Rails.application.config.to_prepare do
  Integrations::Watch.demanded_by(Feeds::Subscription)
end
