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
            messageArray = @message_store[event.server.id][:joinMessage]
            reply = ''
            messageArray.each do |s|
                reply << placeholderReplacement(event, s)
            end
            target_channel.send_message reply
        end
    end

    member_leave do |event|
        target_channel = event.server.text_channels.sort_by { |channel| [channel.id] }.first
        @message_store.transaction do
            messageArray = @message_store[event.server.id][:leaveMessage]
            reply = ''
            messageArray.each do |s|
                reply << placeholderReplacement(event, s)
            end
            target_channel.send_message reply
        end
    end

    attrs = {
        permission_level: 1,
        permission_message: false,
        usage: '!setJoinMessage <joinMessage> || Replaces "{user}" with the user who joined, and "{role=<roleName>}" with a mention of that role.',
        description: 'Sets a message for when a user joins the server.',
        min_args: 1
    }
    command :setJoinMessage, attrs do |event, *args|
        @message_store.transaction do
            @message_store[event.server.id][:joinMessage] = args
            event.respond "Set join message to \"#{args.join(' ')}\""
        end
    end

    attrs = {
        permission_level: 1,
        permission_message: false,
        usage: '!setLeaveMessage <leaveMessage> || Replaces "{user}" with the user who joined, and "{role=<roleName>}" with a mention of that role.',
        description: 'Sets a message for when a user leaves the server.',
        min_args: 1
    }
    command :setLeaveMessage, attrs do |event, *args|
        @message_store.transaction do
            @message_store[event.server.id][:leaveMessage] = args
            event.respond "Set leave message to \"#{args.join(' ')}\""
        end
    end

    private_class_method def self.placeholderReplacement(event, s)
        roleMatch = s.match(/\{role=(.+)\}(.+)?/)
        userMatch = s.match(/\{user\}(.*)/)
        return "#{event.server.roles.find { |role| role.name == roleMatch[1] }.mention}#{roleMatch[2]} " if roleMatch

        return "#{event.user.mention}#{userMatch[1]} " if userMatch

        "#{s} "
    end
end
