require_relative 'self_assigning_roles'
require_relative 'join_leave_messages'

module ServerSystem
    extend Discordrb::EventContainer

    ready do |event|
        event.bot.servers.each_value do |server|
            set_up_stores_and_permissions event, server
        end
        # event.bot.game = ".help | NEW PREFIX!"
    end

    server_create do |event|
        set_up_stores_and_permissions event, event.server
    end

    private_class_method def self.set_up_stores_and_permissions(event, server)
        SelfAssigningRoles.assignable_roles_store.transaction do
            SelfAssigningRoles.assignable_roles_store[server.id] ||= {
                selfAssigningRoles: [],
                aliases: {},
                logChannel: 0
            }
        end
        JoinLeaveMessages.message_store.transaction do
            JoinLeaveMessages.message_store[server.id] ||= {
                joinMessage: '',
                leaveMessage: ''
            }
        end
        begin
            event.bot.set_role_permission(server.roles.find { |role| role.name == 'BotCommand' }.id, 1)
        rescue StandardError
            botCommand = server.create_role
            botCommand.name = 'BotCommand'
            server.owner.pm "I went ahead and created a 'BotCommand' role on '#{server.name}'. "\
                            "Since that's how I know who may use staff commands, you might want to move it up a bit."
        end
    end
end
