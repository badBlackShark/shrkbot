# frozen_string_literal: true

class Components::Feeds::AddPage < Components::Base
  def initialize(server_configuration:, source:)
    @config = server_configuration
    @source = source
  end

  def view_template(&)
    render Components::ServerPage.new(server_configuration: @config, crumbs:) do
      yield
    end
  end

  private

  def crumbs
    [
      {label: PluginCatalog.find(@source.plugin_key).name, href: PluginPaths.for(@config, @source.plugin_key)},
      {label: t(".#{@source.key}.title")}
    ]
  end
end
