# frozen_string_literal: true

module ConfigBus
  CHANNEL = "shrkbot:config"

  module_function

  def sync_commands(server_configuration)
    publish(type: "commands_sync", discord_id: server_configuration.discord_id)
  end

  def repost_roles(role_set)
    publish(type: "roles_repost", set_id: role_set.id)
  end

  def post_roles(role_set)
    publish(type: "roles_post", set_id: role_set.id)
  end

  def delete_roles_message(channel_id:, message_id:)
    publish(type: "roles_message_delete", channel_id:, message_id:)
  end

  def remove_roles_menu(role_set)
    publish(type: "roles_menu_remove", set_id: role_set.id)
  end

  def publish(payload)
    url = BotConfig.redis_url
    if url.nil?
      Rails.logger.warn("[ConfigBus] REDIS_URL not set — dropping #{payload[:type]}")
      return
    end

    Redis.new(url:).publish(CHANNEL, JSON.generate(payload))
  rescue Redis::BaseConnectionError => e
    Rails.logger.error("[ConfigBus] dropping #{payload[:type]} — #{e.class}: #{e.message}")
  end
end
