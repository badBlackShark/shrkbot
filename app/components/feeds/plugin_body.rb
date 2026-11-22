# frozen_string_literal: true

class Components::Feeds::PluginBody < Components::Base
  def initialize(server_configuration:, plugin_key:, selected: nil)
    @config = server_configuration
    @plugin_key = plugin_key
    @selected = selected
  end

  def view_template
    render Components::ConfigSections.new(key: @plugin_key.to_s) do
      if sources.one?
        render Components::Feeds::SubscriptionList.new(server_configuration: @config, source: sources.first)
      else
        render Components::Feeds::SourceTabs.new(server_configuration: @config, plugin_key: @plugin_key, selected: @selected)
      end
    end
  end

  private

  def sources
    @sources ||= ::Feeds.sources_for_plugin(@plugin_key)
  end
end
