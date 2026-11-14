# frozen_string_literal: true

class PluginPaths
  def self.dashboard_for(discord_id)
    helpers = Rails.application.routes.url_helpers
    discord_id.negative? ? helpers.preview_path : helpers.server_path(discord_id)
  end

  def self.for(server_configuration, key)
    raise ArgumentError, "unknown plugin key #{key.inspect}" unless known?(key)

    return preview_for(key) if server_configuration.preview?

    Rails.application.routes.url_helpers.public_send("server_#{key}_path", server_configuration.discord_id)
  end

  def self.preview_for(key)
    raise ArgumentError, "no preview route for bespoke plugin #{key.inspect}" if bespoke?(key)

    Rails.application.routes.url_helpers.public_send("preview_#{key}_path")
  end

  private_class_method def self.known?(key)
    PluginCatalog.find(key).present? || PluginCatalog::GLOBAL_KEYS.include?(key.to_sym)
  end

  private_class_method def self.bespoke?(key)
    PluginCatalog.find(key)&.bespoke || false
  end
end
