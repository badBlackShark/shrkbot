class Shrkbot::OwnerMessage
  include Discord::Plugin

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new("sendOwnerMessage"),
      PermissionChecker.new(PermissionLevel::Creator),
      ArgumentChecker.new(1),
    }
  )]
  def send_owner_message(payload, ctx)
    message = ctx[ArgumentChecker::Result].args.join(" ")

    guilds = Shrkbot.bot.cache.guilds.values
    unique_owners = guilds.uniq { |g| g.owner_id }
    unique_owners.each do |guild|
      message += "\n\nYou are receiving this message because you're the owner of at least one server that this bot is on."
      client.create_message(client.create_dm(guild.owner_id).id, message)
      owner = Shrkbot.bot.cache.resolve_user(guild.owner_id)
      client.create_message(payload.channel_id, "Sent message to #{owner.username}##{owner.discriminator}, owner of *#{guild.name}*.")
    end

    client.create_message(payload.channel_id, "Sent message to the #{unique_owners.size} owner(s) of #{guilds.size} guild(s).")
  end
end
