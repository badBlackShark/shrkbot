require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Hand-defined namespace for app/operations (mapped via push_dir below).
module Ops
end

module App
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Plugins live in app/plugins/<plugin>/ (an auto-rooted app dir). Collapse the
    # commands/ and events/ subfolders out of the constant path so files map to
    # Reminders::Remind, not Reminders::Commands::Remind.
    Rails.autoloaders.main.collapse(Rails.root.join("app/plugins/*/commands"))
    Rails.autoloaders.main.collapse(Rails.root.join("app/plugins/*/events"))

    # Map app/operations to the Ops:: namespace (files stay flat, no ops/ subdir).
    Rails.autoloaders.main.push_dir(Rails.root.join("app/operations").to_s, namespace: Ops)

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil
  end
end
