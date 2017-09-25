# Allows you to send customizable messages when a user joins / leaves a server.
module JoinLeaveMessages
  extend Discordrb::EventContainer
  extend Discordrb::Commands::CommandContainer

  # TODO: Multithread

  # Getter for the message store
  def self.message_store
    @message_store
  end
  @message_store = YAML::Store.new 'messages.yaml'

  member_join do |event|
    # Sends in the oldest channel on the server (#general). If that's deleted, you may have a problem.
    target_channel = event.server.text_channels.sort_by { |channel| [channel.id] }.first
    @message_store.transaction do
      message_array = @message_store[event.server.id][:join_message]
      reply = ''
      message_array.each do |s|
        # Replacing {user} and {role=<roleName>}
        reply << placeholder_replacement(event, s)
      end
      target_channel.send_message reply
    end
  end

  member_leave do |event| # Works exactly like member_join
    target_channel = event.server.text_channels.sort_by { |channel| [channel.id] }.first
    @message_store.transaction do
      message_array = @message_store[event.server.id][:leave_message]
      reply = ''
      message_array.each do |s|
        reply << placeholder_replacement(event, s)
      end
      target_channel.send_message reply
    end
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: '.setJoinMessage <joinMessage> || Valid placeholders: {user}, {role=<roleName}',
    description: 'Sets a message for when a user joins the server.',
    min_args: 1
  }
  command :setJoinMessage, attrs do |event, *args|
    @message_store.transaction do
      @message_store[event.server.id][:join_message] = args
      event.message.react(EmojiTranslator.name_to_unicode('checkmark'))
    end
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: '.setLeaveMessage <leaveMessage> || Valid placeholders: {user}, {role=<roleName}',
    description: 'Sets a message for when a user leaves the server.',
    min_args: 1
  }
  command :setLeaveMessage, attrs do |event, *args|
    @message_store.transaction do
      @message_store[event.server.id][:leave_message] = args
      event.message.react(EmojiTranslator.name_to_unicode('checkmark'))
    end
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: '.joinMessage',
    description: 'Displays the message for when a user joins the server.'
  }
  command :joinMessage, attrs do |event|
    @message_store.transaction do
      event.channel.split_send @message_store[event.server.id][:join_message].join(' ')
      nil
    end
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: '.leaveMessage',
    description: 'Displays the message for when a user leaves the server.'
  }
  command :leaveMessage, attrs do |event|
    @message_store.transaction do
      event.respond @message_store[event.server.id][:leave_message].join(' ')
    end
  end

  private_class_method def self.placeholder_replacement(event, s)
    role_match = s.match(/\{role=(.+)\}(.+)?/)
    user_match = s.match(/\{user\}(.*)/)

    # Mentions the specified role. Case-insensitive
    return "#{event.server.roles.find { |role| role.name.casecmp(role_match[1]).zero? }.mention}#{role_match[2]} " if role_match

    if user_match
      if event.class == Discordrb::Events::ServerMemberAddEvent
        return "#{event.user.mention}#{user_match[1]} "
      elsif event.class == Discordrb::Events::ServerMemberDeleteEvent
        # No mention on leave, because user might not be cached anymore.
        return "#{event.user.distinct}#{user_match[1]} "
      end
    end

    "#{s} "
  end
end
