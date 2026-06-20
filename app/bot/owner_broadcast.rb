module OwnerBroadcast
  FOOTER = "\n\nYou're receiving this because you own at least one server that shrkbot is in."
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
    bot.pm_channel(owner_id).send_message(content + FOOTER)
    true
  rescue => e
    Rails.logger.warn("[OwnerBroadcast] could not DM owner #{owner_id}: #{e.class}: #{e.message}")
    false
  end
end
