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

  private

  def manageable_keys
    @manageable_keys ||= @manages_server ? configurable_keys : Set.new
  end

  def configurable_keys
    @configurable_keys ||= (PluginCatalog.visible_for(@server_configuration).map(&:key) + PluginCatalog::GLOBAL_KEYS).to_set
  end
end
