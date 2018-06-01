# Allows you to send customizable messages when a user joins / leaves a server.
module JoinLeaveMessages
  extend Discordrb::EventContainer
  extend Discordrb::Commands::CommandContainer
  extend self

  member_join do |event|
    # Sends in #general (the oldest channel). If that's deleted, you may have a problem.
    message = DB.read_value("shrk_server_#{event.server.id}".to_sym, :join_message)&.split(' ')
    next unless message
    target_channel = get_message_channel(event.server)
    reply = ''
    message.each do |s|
      # Replacing {user} and {role=<roleName>}
      reply << placeholder_replacement(event, s)
    end
    target_channel.send_message reply
  end

  member_leave do |event| # Works exactly like member_join
    message = DB.read_value("shrk_server_#{event.server.id}".to_sym, :leave_message)&.split(' ')
    return unless message
    target_channel = get_message_channel(event.server)
    reply = ''
    message.each do |s|
      reply << placeholder_replacement(event, s)
    end
    target_channel.send_message reply
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: 'setJoinMessage <joinMessage>',
    description: "Sets a message to display when a user joins the server. Valid placeholders:\n"\
                 "`{user}`: Mentiones the user that joined.\n`{role=<roleName>}`: Mentions a role.",
    min_args: 1
  }
  command :setjoinmessage, attrs do |event, *args|
    DB.update_string_value("shrk_server_#{event.server.id}".to_sym, :join_message, args.join(' '))
    Reactions.confirm(event.message)
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: 'setLeaveMessage <leaveMessage>',
    description: "Sets a message to display when a user leaves the server. Valid placeholders:\n"\
                 "`{user}`: Mentiones the user that joined.\n`{role=<roleName>}`: Mentions a role.",
    min_args: 1
  }
  command :setleavemessage, attrs do |event, *args|
    DB.update_string_value("shrk_server_#{event.server.id}".to_sym, :leave_message, args.join(' '))
    Reactions.confirm(event.message)
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: 'joinMessage',
    description: 'Displays the message for when a user joins the server.'
  }
  command :joinmessage, attrs do |event|
    DB.read_value("shrk_server_#{event.server.id}".to_sym, :join_message)
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: 'leaveMessage',
    description: 'Displays the message for when a user leaves the server.'
  }
  command :leavemessage, attrs do |event|
    DB.read_value("shrk_server_#{event.server.id}".to_sym, :leave_message)
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: 'setMessageChannel <channelName>',
    description: 'Sets the channel where the bot logs role assigns.',
    min_args: 1
  }
  # This is the manual setter, the database attempts to assign a default value when initializing.
  command :setmessagechannel, attrs do |event, *args|
    channel = event.server.channels.find { |s_channel| s_channel.name.casecmp?(args.join(' ')) }
    next "That channel doesn't exist." unless channel

    DB.update_value("shrk_server_#{event.server.id}".to_sym, :message_channel, channel.id)
    Reactions.confirm(event.message)
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: 'messageChannel?',
    description: 'Links the channel for join / leave messages, in case you forgot which one it is.'
  }
  command :messagechannel?, attrs do |event|
    message_channel = DB.read_value("shrk_server_#{event.server.id}".to_sym, :message_channel)

    next "The channel for join / leave messages is <##{message_channel}>." if message_channel

    'There is no channel for join / leave messages. '\
    'Please set one by using the `setMessageChannel` command.'
  end

  def init_message_channel(server)
    return if DB.read_value("shrk_server_#{server.id}".to_sym, :message_channel)
    # Join / leave messages will be sent in the top channel of the server.
    # You probably gonna wanna change this.
    message_channel = server.default_channel
    DB.unique_insert("shrk_server_#{server.id}".to_sym, :message_channel, message_channel.id)
    LOGGER.log(
      server,
      "Set <##{message_channel.id}> as the channel where join / leave " \
      'messages will be sent. You can change it by using the `setMessageChannel` command.'
    )
  end

  private

  def placeholder_replacement(event, s)
    role_match = s.match(/(.*)\{role=(.+)\}(.*)/)&.captures
    user_match = s.match(/(.*)(\{user\})(.*)/)&.captures

    # Mentions the specified role. Case-insensitive
    return replace_role_match(event, role_match) if role_match
    return replace_user_match(event, user_match) if user_match

    "#{s} "
  end

  def replace_role_match(event, role_match)
    mention = ''
    role_match.each do |m|
      mention << (event.server.roles.find { |role| role.name.casecmp?(m) }&.mention || m)
    end
    mention << ' '
  end

  def replace_user_match(event, user_match)
    mention = ''
    if event.class == Discordrb::Events::ServerMemberAddEvent
      user_match.each do |m|
        mention << (m.match?(/\{user\}/) ? event.user.mention : m)
      end
    elsif event.class == Discordrb::Events::ServerMemberDeleteEvent
      # No mention on leave, because user might not be cached anymore.
      user_match.each do |m|
        mention << (m.match?(/\{user\}/) ? event.user.distinct : m)
      end
    end
    mention << ' '
  end

  def get_message_channel(server)
    SHRK.channel(DB.read_value("shrk_server_#{server.id}".to_sym, :message_channel))
  end
end
