# frozen_string_literal: true

class Components::Feeds::Overview < Components::Base
  def initialize(server_configuration:, enable_error: nil)
    @config = server_configuration
    @enable_error = enable_error
  end

  def view_template
    render Components::ConfigSections.new(key: "feeds", enable_error: @enable_error) do
      render Components::SubPluginDirectory.new(
        server_configuration: @config,
        rows: SubPluginStatus.rows(@config, parent: :feeds, enabled_keys:),
        group_enabled: enabled_keys.include?(:feeds)
      )
    end
  end

  private

  def enabled_keys
    @enabled_keys ||= @config.enabled_plugin_keys
  end
end
