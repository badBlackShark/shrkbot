# frozen_string_literal: true

Rails.application.config.to_prepare do
  Integrations::Watch.demanded_by(Feeds::Subscription)
  Rails.autoloaders.main.eager_load_dir(Rails.root.join("app/jobs"))
end
