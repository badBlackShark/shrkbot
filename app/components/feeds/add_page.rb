# frozen_string_literal: true

class Components::Feeds::AddPage < Components::Base
  def initialize(server_configuration:, plugin_key:)
    @config = server_configuration
    @plugin_key = plugin_key
  end

  def view_template(&)
    render Components::ServerPage.new(server_configuration: @config, crumbs:) do
      yield
    end
  end

  private

  def crumbs
    [
      {label: PluginCatalog.find(@plugin_key).name, href: PluginPaths.for(@config, @plugin_key)},
      {label: t(".title")}
    ]
  end
end
