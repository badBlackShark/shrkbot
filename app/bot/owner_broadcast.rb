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

    Result.new(owner_count: owner_ids.size, sent: sent, server_count: servers.size)
  end

  def deliver(bot, owner_id, content)
    rendered = message(content)
    bot.pm_channel(owner_id).send_message(nil, false, nil, nil, nil, nil, rendered[:components], rendered[:flags])
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
