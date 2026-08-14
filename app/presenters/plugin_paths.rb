# frozen_string_literal: true

class PluginPaths
  def self.dashboard_for(discord_id)
    helpers = Rails.application.routes.url_helpers
    discord_id.negative? ? helpers.preview_path : helpers.server_path(discord_id)
  end

  def self.for(server_configuration, key)
    raise ArgumentError, "unknown plugin key #{key.inspect}" unless known?(key)

    helpers = Rails.application.routes.url_helpers
    if server_configuration.preview?
      raise ArgumentError, "no preview route for bespoke plugin #{key.inspect}" if bespoke?(key)

      helpers.public_send("preview_#{key}_path")
    else
      helpers.public_send("server_#{key}_path", server_configuration.discord_id)
    end
  end

  private_class_method def self.known?(key)
    PluginCatalog.find(key).present? || PluginCatalog::GLOBAL_KEYS.include?(key.to_sym)
  end

  private_class_method def self.bespoke?(key)
    PluginCatalog.find(key)&.bespoke || false
  end
end
