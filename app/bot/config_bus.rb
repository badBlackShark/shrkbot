# frozen_string_literal: true

module ConfigBus
  CHANNEL = "shrkbot:config"

  module_function

  def repost_roles(role_set)
    publish(type: "roles_repost", set_id: role_set.id)
  end

  def publish(payload)
    Redis.new(url: BotConfig.redis_url).publish(CHANNEL, JSON.generate(payload))
  end
end
