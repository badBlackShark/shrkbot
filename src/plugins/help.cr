class Shrkbot::Help
  include Discord::Plugin

  def initialize
    @plugin_list = PluginList.from_yaml(File.read("./src/commands.yml"))
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new("help"),
      ArgumentChecker.new(0, 1),
    }
  )]
  def help(payload, ctx)
    guild = client.cache.try &.resolve_channel(payload.channel_id).guild_id
    cmd = ctx[ArgumentChecker::Result].args.first?

    embed = Discord::Embed.new
    perm_level = Permissions.permission_level(payload.author.id, guild)

    if cmd
      command = @plugin_list.single_command(cmd, perm_level, guild)
      if command.is_a?(Symbol)
        case command
        when :not_found
          msg = client.create_message(payload.channel_id, "I couldn't find that command. Use the help command to see which commands exist.")
          sleep 5
          client.delete_message(payload.channel_id, msg.id)
          client.delete_message(payload.channel_id, payload.id)
          return
        when :no_perms
          msg = client.create_message(payload.channel_id, "You don't have the necessary permissions to use this command.")
          sleep 5
          client.delete_message(payload.channel_id, msg.id)
          client.delete_message(payload.channel_id, payload.id)
          return
        end
      else
        embed.title = command[0]
        embed.description = command[1]
      end
    else
      embed.title = "All the commands for shrkbot you can use."
      embed.description = "Required arguments surrounded by `<>`, optional arguments surrounded by `[]`."
      embed.fields = @plugin_list.to_embed_fields(perm_level, guild)

      case perm_level
      when PermissionLevel::Moderator
        embed.footer = Discord::EmbedFooter.new(text: "Staff commands are marked accordingly.")
      when PermissionLevel::Creator
        embed.footer = Discord::EmbedFooter.new(text: "Staff and creator commands are marked accordingly.")
      end
    end

    embed.colour = 0x38AFE5

    client.create_message(payload.channel_id, "", embed)
  end

  @[Discord::Handler(
    event: :ready
  )]
  def set_game(payload)
    # For some reason I need to send this 0, otherwise Discord refuses to update the game.
    client.status_update(game: Discord::GamePlaying.new("your commands", Discord::GamePlaying::Type::Listening))
  end
end
