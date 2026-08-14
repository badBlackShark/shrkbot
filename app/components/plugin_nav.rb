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
    lfg: "game-controller",
    twilight_struggle: "trophy"
  }.freeze

  def plugin_icon(key)
    ICONS.fetch(key.to_sym)
  end
end
