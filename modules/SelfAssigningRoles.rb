require 'thread'

require_relative '../lib/EmojiTranslator'

module SelfAssigningRoles
    extend Discordrb::Commands::CommandContainer

    roleAssigns = Discordrb::Commands::Bucket.new(limit = 1, time_span = 10, delay = 10)
    syncr = Mutex.new

    attrs = {
        permission_level: 1,
        permission_message: false,
        usage: ".setLogChannel <channelName>",
        description: "Sets the channel where the bot logs role assigns.",
        min_args: 1
    }
    command :setLogChannel, attrs do |event, *args|
        $assignableRolesStore.transaction do
            channel = event.server.channels.find {|channel| channel.name.downcase == args.join(' ').downcase}
            next "That channel doesn't exist." unless channel

            $assignableRolesStore[event.server.id][:logChannel] = channel.id
            event.message.react(EmojiTranslator.name_to_unicode('checkmark'))
        end
    end


    attrs = {
        permission_level: 1,
        permission_message: false,
        usage: ".addToSelfAssign <roleName>",
        description: "Adds a role to the list of self-assignable roles.",
        min_args: 1
    }
    command :addToSelfAssign, attrs do |event, *args|
        $assignableRolesStore.transaction do
            role = event.server.roles.select {|role| role.name.downcase == args.join(' ').downcase}.first
            next "I couldn't find the role you were looking for." unless role

            next "That role's rank is too high." if role.position >= event.bot.profile.on(event.server).roles.sort_by {|r| [r.position, r.id]}.last.id

            if $assignableRolesStore[event.server.id][:selfAssigningRoles].include?(role.id)
                event.send_temporary_message "The role #{args.join(" ").downcase} is already self-assignable.", 10
                event.message.delete
                return
            end

            $assignableRolesStore[event.server.id][:selfAssigningRoles].push(role.id)
            event.message.react(EmojiTranslator.name_to_unicode('checkmark'))
        end
    end

    attrs = {
        permission_level: 1,
        permission_message: false,
        usage: ".removeFromSelfAssign <roleName>",
        description: "Removes a role from the list of self-assignable roles.",
        min_args: 1
    }
    command :removeFromSelfAssign, attrs do |event, *args|
        $assignableRolesStore.transaction do
            role = event.server.roles.select {|role| role.name.downcase == args.join(" ").downcase}.first.id
            unless $assignableRolesStore[event.server.id][:selfAssigningRoles].include?(role)
                event.respond "The role #{args.join(" ").downcase} isn't self-assignable."
                return
            end
            $assignableRolesStore[event.server.id][:selfAssigningRoles].delete(role)
            event.message.react(EmojiTranslator.name_to_unicode('checkmark'))
        end
    end


    attrs = {
        usage: ".roles",
        description: "Returns a list of the roles you can assign yourself with !giveMe."
    }
    command :roles, attrs do |event|
        $assignableRolesStore.transaction do
            reply = "The self assignable roles are: "
            roles = Array.new
            $assignableRolesStore[event.server.id][:selfAssigningRoles].each do |role|
                roles.push(event.server.roles.select {|sRole| sRole.id == role}.first.name)
            end
            reply << "#{roles.join(", ")}. Use `.giveMe <role>` to assign one to yourself."
            message = event.respond reply
            message.react(EmojiTranslator.name_to_unicode('crossmark'))
            event.bot.add_await(:"delete_#{message.id}", Discordrb::Events::ReactionAddEvent, emoji: EmojiTranslator.name_to_unicode('crossmark')) do |reaction_event|
                next false unless reaction_event.message.id == message.id
                message.delete
            end
        end
        nil
    end


    attrs = {
        permission_level: 1,
        permission_message: false,
        min_args: 2,
        usage: ".addAlias {roleName} {roleAlias}",
        description: "Adds an alias for an existing role"
    }
    command :addAlias, attrs do |event, *args|
        arguments = args.join(" ").match(/\{(.+)\} \{(.+)\}/)
        next "Too few arguments or incorrect syntax for command `addAlias`!" unless arguments

        roleName = arguments[1].downcase
        roleAlias = arguments[2].downcase
        $assignableRolesStore.transaction do
            begin
                roleID = event.server.roles.select {|role| role.name.downcase == roleName}.first.id
            rescue Exception => e
                event.respond "The role you want to add an alias for doesn't exist."
                return
            end
            unless $assignableRolesStore[event.server.id][:selfAssigningRoles].include?(roleID)
                event.respond "The role you want to add an alias for isn't self-assignable."\
                    " Please make it self assignable first, and then add an alias."
                return
            end
            if $assignableRolesStore[event.server.id][:aliases].keys.include?(roleAlias)
                event.respond "That alias already exists."
                event.message.delete
                return
            end
            $assignableRolesStore[event.server.id][:aliases][roleAlias] = roleID

            event.message.react(EmojiTranslator.name_to_unicode('checkmark'))
        end
    end


    attrs = {
        permission_level: 1,
        permission_message: false,
        min_args: 1,
        usage: ".removeAlias roleAlias",
        description: "Removes an alias for an existing role."
    }
    command :removeAlias, attrs do |event, *args|
        roleAlias = args.join(" ").downcase
        $assignableRolesStore.transaction do
            roleID = $assignableRolesStore[event.server.id][:aliases].delete(roleAlias)
            if roleID
                event.message.react(EmojiTranslator.name_to_unicode('checkmark'))
            else
                event.send_temporary_message "Alias \"#{roleAlias}\" doesn't exist.", 10
            end
        end
    end


    attrs = {
        usage: ".alises",
        description: "A list of all available aliases."
    }
    command :aliases, attrs do |event|
        $assignableRolesStore.transaction do
            response = String.new
            message = event.channel.send_embed do |embed|
                embed.title = "All available aliases"

                roleIDs = $assignableRolesStore[event.server.id][:aliases].values.uniq
                roleIDs.each do |roleID|
                    embed.add_field(name: idToRolename(event, roleID), value: $assignableRolesStore[event.server.id][:aliases].map{ |k,v| v==roleID ? "• #{k}" : nil}.compact.join("\n"))
                end
            end
            message.react(EmojiTranslator.name_to_unicode('crossmark'))
            event.bot.add_await(:"delete_#{message.id}", Discordrb::Events::ReactionAddEvent, emoji: EmojiTranslator.name_to_unicode('crossmark')) do |reaction_event|
                next false unless reaction_event.message.id == message.id
                message.delete
            end
        end
        nil
    end


    attrs = {
        usage: ".giveMe <roleName>",
        description: "Assign a role to yourself."
    }
    command :giveMe, attrs do |event, *args|
        t = Thread.new{
            syncr.synchronize{
                $assignableRolesStore.transaction do
                    begin
                        roleName = args.join(" ").downcase
                        roleID = aliasToID(event, roleName)
                        roleID = roleID ? roleID : event.server.roles.select {|role| role.name.downcase == roleName}.first.id
                    rescue Exception => e
                        event.send_temporary_message("I couldn't find the role you were looking for. For a list of all available role type `!roles`.", 10)
                    end
                    return unless $assignableRolesStore[event.server.id][:selfAssigningRoles].include?(roleID)
                    roles = $assignableRolesStore[event.server.id][:selfAssigningRoles]

                    userRoles = Array.new
                    event.user.roles.each do |role|
                        userRoles << role.id
                    end
                    return if userRoles.include?(roleID)

                    deleteExistingRoles(event, roles, userRoles)
                    newRole = event.user.add_role (event.server.roles.select {|role| role.id == roleID}.first)
                    event.message.react(EmojiTranslator.name_to_unicode('checkmark'))
                    logChannel = $assignableRolesStore[event.server.id][:logChannel]
                    event.bot.channel(logChannel).send_message("#{event.user.name} gave himself the role \"#{idToRolename(event, roleID)}\".")
                end
            }
        }
        nil
    end



    private

    def self.idToRolename event, roleID
        return event.server.roles.select {|role| role.id == roleID}.first.name
    end

    def self.aliasToID event, roleAlias
        return $assignableRolesStore[event.server.id][:aliases][roleAlias]
    end

    def self.deleteExistingRoles event, assignableRoles, userRoles
        assignableRoles.each do |aRole|
            if userRoles.include?(aRole)
                event.user.remove_role (event.server.roles.select {|role| role.id == aRole}.first)
                sleep 0.1
            end
        end
    end
end
