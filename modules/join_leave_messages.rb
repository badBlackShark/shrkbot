module JoinLeaveMessages
  extend Discordrb::EventContainer
  extend Discordrb::Commands::CommandContainer

  # Getter for the yaml store
  def self.message_store
    @message_store
  end
  @message_store = YAML::Store.new 'messages.yaml'

  member_join do |event|
    target_channel = event.server.text_channels.sort_by { |channel| [channel.id] }.first
    @message_store.transaction do
      message_array = @message_store[event.server.id][:join_message]
      reply = ''
      message_array.each do |s|
        reply << placeholder_replacement(event, s)
      end
      target_channel.send_message reply
    end
  end

  member_leave do |event|
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
    usage: '!setJoinMessage <joinMessage> || Valid placeholders: {user}, {role=<roleName}',
    description: 'Sets a message for when a user joins the server.',
    min_args: 1
  }
  command :setJoinMessage, attrs do |event, *args|
    @message_store.transaction do
      @message_store[event.server.id][:join_message] = args
      event.respond "Set join message to \"#{args.join(' ')}\""
    end
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: '!setLeaveMessage <leaveMessage> || Valid placeholders: {user}, {role=<roleName}',
    description: 'Sets a message for when a user leaves the server.',
    min_args: 1
  }
  command :setLeaveMessage, attrs do |event, *args|
    @message_store.transaction do
      @message_store[event.server.id][:leave_message] = args
      event.respond "Set leave message to \"#{args.join(' ')}\""
    end
  end

  private_class_method def self.placeholder_replacement(event, s)
    role_match = s.match(/\{role=(.+)\}(.+)?/)
    user_match = s.match(/\{user\}(.*)/)
    return "#{event.server.roles.find { |role| role.name.casecmp(role_match[1]).zero? }.mention}#{role_match[2]} " if role_match

    if user_match
      if event.class == Discordrb::Events::ServerMemberAddEvent
        return "#{event.user.mention}#{user_match[1]} "
      elsif event.class == Discordrb::Events::ServerMemberDeleteEvent
        return "#{event.user.distinct}#{user_match[1]} "
      end
    end

    "#{s} "
  end
end
