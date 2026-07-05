# frozen_string_literal: true

module OwnerBroadcast
  FOOTER = "-# You're receiving this because you own at least one server that shrkbot is in."
  Result = Data.define(:owner_count, :sent, :server_count)

  module_function

  def call(bots:, content:)
    servers = bots.flat_map { |bot| bot.servers.values }
    owner_ids = servers.filter_map { |server| server.owner&.id }.uniq
    messenger = bots.first
    sent = owner_ids.count { |owner_id| deliver(messenger, owner_id, content) }

    Result.new(owner_count: owner_ids.size, sent:, server_count: servers.size)
  end

  def deliver(bot, owner_id, content)
    Discord::Components.send_to(bot.pm_channel(owner_id), message(content))
    true
  rescue => e
    Rails.logger.warn("[OwnerBroadcast] could not DM owner #{owner_id}: #{e.class}: #{e.message}")
    false
  end

  def message(content)
    Discord::Components.container(
      [
        Discord::Components.text(content),
        Discord::Components.separator,
        Discord::Components.text(FOOTER)
      ]
    )
  end
end
