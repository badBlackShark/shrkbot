# frozen_string_literal: true

class PluginAccess
  def initialize(user:, server_configuration:, manages_server:)
    @user = user
    @server_configuration = server_configuration
    @manages_server = manages_server
  end

  def manage?(key)
    manageable_keys.include?(key.to_sym)
  end

  def visible?(key)
    configurable_keys.include?(key.to_sym)
  end

  def toggle?(key)
    @manages_server && manage?(key)
  end

  private

  def manageable_keys
    @manageable_keys ||= @manages_server ? configurable_keys : administered_keys
  end

  def administered_keys
    return Set.new unless configurable_keys.include?(::TwilightStruggle::PLUGIN_KEY) && organiser?

    Set[::TwilightStruggle::PLUGIN_KEY]
  end

  def organiser?
    ::TwilightStruggle::OrganiserServers
      .discord_ids_for(@user.discord_id)
      .include?(@server_configuration.discord_id)
  end

  def configurable_keys
    @configurable_keys ||= (PluginCatalog.visible_for(@server_configuration).map(&:key) + PluginCatalog::GLOBAL_KEYS).to_set
  end
end
