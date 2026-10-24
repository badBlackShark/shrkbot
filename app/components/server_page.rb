# frozen_string_literal: true

class Components::ServerPage < Components::Base
  def initialize(server_configuration:, crumbs:)
    @server_configuration = server_configuration
    @crumbs = crumbs
  end

  def view_template(&)
    div(class: "mx-auto max-w-3xl px-6 pb-28 pt-8") do
      render Components::Breadcrumb.new(base_crumbs + @crumbs)
      yield
    end
  end

  private

  def base_crumbs
    [
      {label: t(".servers"), href: servers_path},
      {label: @server_configuration.name || t(".dashboard"), href: PluginPaths.dashboard_for(@server_configuration.discord_id)}
    ]
  end
end
