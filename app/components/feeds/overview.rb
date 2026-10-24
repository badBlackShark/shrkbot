# frozen_string_literal: true

class Components::Feeds::Overview < Components::Base
  def initialize(server_configuration:, enable_error: nil)
    @config = server_configuration
    @enable_error = enable_error
  end

  def view_template
    render Components::ConfigSections.new(key: "feeds", enable_error: @enable_error) do
      render Components::SubPluginDirectory.new(server_configuration: @config, parent: :feeds)
    end
  end
end
