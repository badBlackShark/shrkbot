# frozen_string_literal: true

class Components::Feeds::AddPage < Components::Base
  def initialize(server_configuration:, plugin_key:)
    @config = server_configuration
    @plugin_key = plugin_key
  end

  def view_template(&)
    div(class: "mx-auto max-w-3xl px-6 pb-28 pt-8") do
      render Components::Breadcrumb.new(crumbs)
      yield
    end
  end

  private

  def crumbs
    [
      {label: t("components.config_page.servers"), href: servers_path},
      {label: @config.name || t("components.config_page.dashboard"), href: PluginPaths.dashboard_for(@config.discord_id)},
      {label: PluginCatalog.find(@plugin_key).name, href: PluginPaths.for(@config, @plugin_key)},
      {label: t(".title")}
    ]
  end
end
