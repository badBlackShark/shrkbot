module ServerSystem
    extend Discordrb::EventContainer

    ready do |event|
        event.bot.servers.values.each do |server|
            set_up_stores_and_permissions event, server
        end
        # event.bot.game = ".help | NEW PREFIX!"
    end

    server_create do |event|
        set_up_stores_and_permissions event, event.server
    end


    private

    def self.set_up_stores_and_permissions event, server
        $assignableRolesStore.transaction do
            $assignableRolesStore[server.id] ||= {
                selfAssigningRoles: Array.new,
                aliases: Hash.new,
                logChannel: 0
            }
        end
        $messageStore.transaction do
            $messageStore[server.id] ||= {
                :joinMessage => "",
                :leaveMessage => ""
            }
        end
        begin
            event.bot.set_role_permission(server.roles.find{|role| role.name == "BotCommand"}.id, 1)
        rescue Exception => e
            botCommand = server.create_role
            botCommand.name = "BotCommand"
            server.owner.pm "I went ahead and created a 'BotCommand' role on '#{server.name}'. "\
                            "Since that's how I know who may use staff commands, you might want to move it up a bit."
        end
    end
end
