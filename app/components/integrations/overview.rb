# frozen_string_literal: true

class Components::Integrations::Overview < Components::Base
  def initialize(server_configuration:)
    @config = server_configuration
  end

  def view_template
    render Components::ConfigSections.new(key: "integrations") do
      render Components::SubPluginDirectory.new(server_configuration: @config, parent: :integrations)
    end
  end
end
