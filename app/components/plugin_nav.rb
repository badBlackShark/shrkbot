# frozen_string_literal: true

module Components::PluginNav
  ICONS = {
    roles: "users-three",
    welcomes: "hand-waving",
    logging: "scroll",
    reminders: "bell-ringing",
    moderation: "shield",
    spam_protection: "megaphone-slash",
    image_scanning: "scan",
    lfg: "game-controller"
  }.freeze

  def plugin_icon(key)
    ICONS.fetch(key.to_sym)
  end

  def plugin_config_path(server_id, key)
    case key.to_sym
    when :roles then server_roles_path(server_id)
    when :welcomes then server_welcomes_path(server_id)
    when :logging then server_logging_path(server_id)
    when :reminders then server_reminders_path(server_id)
    when :moderation then server_moderation_path(server_id)
    when :spam_protection then server_spam_protection_path(server_id)
    when :image_scanning then server_image_scanning_path(server_id)
    when :lfg then server_lfg_path(server_id)
    end
  end
end
