class Shrkbot::Info
  include Discord::Plugin

  @[Discord::Handler(
    event: :message_create,
    middleware: Command.new("info")
  )]
  def info(payload, _ctx)
    bot = client.cache.try &.resolve_current_user || raise "Cache unavailable"

    embed = Discord::Embed.new
    embed.author = Discord::EmbedAuthor.new(name: bot.username, icon_url: bot.avatar_url)
    embed.description = "I was written in [Crystal](https://crystal-lang.org/) by [badBlackShark](https://github.com/badBlackShark/).\n" \
                        "My code can be found [here](https://github.com/badBlackShark/shrkbot). Want me for your server? [Invite me!](https://discord.com/api/oauth2/authorize?client_id=346043915142561793&permissions=889285718&scope=bot)"
    embed.fields = [Discord::EmbedField.new(
      name: "I was built using these packages",
      value: "**[discordcr](https://github.com/shardlab/discordcr)** *by meew0 and RX14*\n" \
             "**[discordcr-middleware](https://github.com/z64/discordcr-middleware)** *by z64*\n" \
             "**[discordcr-plugin](https://github.com/z64/discordcr-plugin)** *by z64*\n" \
             "**[tasker](https://github.com/spider-gazelle/tasker)** *by spider-gazelle*\n" \
             "**[crystal-db](https://github.com/crystal-lang/crystal-db)** *by crystal-lang*\n" \
             "**[crystal-pg](https://github.com/will/crystal-pg)** *by will*\n" \
             "**[rss](https://github.com/ruivieira/rss)** *by ruivieira*\n" \
             "**[myhtml](https://github.com/kostya/myhtml)** *by kostya*\n" \
             "**[humanize_time](https://github.com/mamantoha/humanize_time)** *by mamantoha*"
    )]

    embed.colour = 0x38AFE5
    embed.footer = Discord::EmbedFooter.new(text: "If you would like to support the project, you can get all the information on that by using the \"donate\" command.")
    client.create_message(payload.channel_id, "", embed)
  end
end
