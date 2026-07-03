# frozen_string_literal: true

module Components::PluginNav
  ICONS = {
    roles: "users-three",
    welcomes: "hand-waving",
    logging: "scroll",
    reminders: "bell-ringing"
  }.freeze

  def plugin_icon(key)
    ICONS.fetch(key.to_sym)
  end

  def plugin_config_path(server_id, key)
    case key.to_sym
    when :roles then server_roles_path(server_id)
    when :welcomes then server_welcomes_path(server_id)
    when :logging then server_logging_path(server_id)
    end
  end
end
