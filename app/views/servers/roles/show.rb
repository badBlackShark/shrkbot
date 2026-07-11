# frozen_string_literal: true

class Views::Servers::Roles::Show < Views::Servers::PluginConfigShow
  private

  def plugin_key
    :roles
  end

  def icon
    "users-three"
  end

  def url
    server_roles_path(@config.discord_id)
  end

  def form
    render Components::Roles::ConfigForm.new(server_configuration: @config)
  end
end
