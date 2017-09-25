require 'thread'

require_relative '../lib/emoji_translator'

module SelfAssigningRoles
  extend Discordrb::Commands::CommandContainer

  # Getter for the yaml store
  def self.assignable_roles_store
    @assignable_roles_store
  end
  @assignable_roles_store = YAML::Store.new 'assignables.yaml'

  @mutex = Mutex.new

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: '.setLogChannel <channelName>',
    description: 'Sets the channel where the bot logs role assigns.',
    min_args: 1
  }
  command :setLogChannel, attrs do |event, *args|
    @assignable_roles_store.transaction do
      channel = event.server.channels.find { |s_channel| s_channel.name.casecmp(args.join(' ')).zero? }
      next "That channel doesn't exist." unless channel

      @assignable_roles_store[event.server.id][:log_channel] = channel.id
      event.message.react(EmojiTranslator.name_to_unicode('checkmark'))
    end
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: '.setAssignmentChannel <channelName>',
    description: 'Sets the channel where the bot displays the role assign message.',
    min_args: 1
  }
  command :setAssignmentChannel, attrs do |event, *args|
    @assignable_roles_store.transaction do
      channel = event.server.channels.find { |s_channel| s_channel.name.casecmp(args.join(' ')).zero? }
      next "That channel doesn't exist." unless channel

      @assignable_roles_store[event.server.id][:assignment_channel] = channel.id
      event.message.react(EmojiTranslator.name_to_unicode('checkmark'))
    end
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: '.addToSelfAssign <roleName>',
    description: 'Adds a role to the list of self-assignable roles.',
    min_args: 1
  }
  command :addToSelfAssign, attrs do |event, *args|
    @assignable_roles_store.transaction do
      role = event.server.roles.find { |s_role| s_role.name.casecmp(args.join(' ')).zero? }
      next "I couldn't find the role you were looking for." unless role

      if role.position >= event.bot.profile.on(event.server).roles.sort_by { |r| [r.position, r.id] }.last.position
        event.send_temporary_message "That role's rank is too high.", 10
        event.message.delete
        return
      end

      if @assignable_roles_store[event.server.id][:self_assigning_roles].include?(role.id)
        event.send_temporary_message "The role #{args.join(' ')} is already self-assignable.", 10
        event.message.delete
        return
      end

      @assignable_roles_store[event.server.id][:self_assigning_roles].push(role.id)
      event.message.react(EmojiTranslator.name_to_unicode('checkmark'))
    end
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: '.removeFromSelfAssign <roleName>',
    description: 'Removes a role from the list of self-assignable roles.',
    min_args: 1
  }
  command :removeFromSelfAssign, attrs do |event, *args|
    @assignable_roles_store.transaction do
      role = event.server.roles.find { |s_role| s_role.name.casecmp(args.join(' ')).zero? }.id
      unless @assignable_roles_store[event.server.id][:self_assigning_roles].include?(role)
        event.respond "The role #{args.join(' ').downcase} isn't self-assignable."
        return
      end
      @assignable_roles_store[event.server.id][:self_assigning_roles].delete(role)
      event.message.react(EmojiTranslator.name_to_unicode('checkmark'))
    end
  end

  attrs = {
    usage: '.roles',
    description: 'Returns a list of the roles you can assign yourself with !giveMe.'
  }
  command :roles, attrs do |event|
    @assignable_roles_store.transaction do
      channel_id = @assignable_roles_store[event.server.id][:self_assigning_roles]
      "In the channel <##{channel_id}> you can find the roles you can assign to yourself."
    end
    nil
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    min_args: 2,
    usage: '.addAlias {roleName} {roleAlias}',
    description: 'Adds an alias for an existing role'
  }
  command :addAlias, attrs do |event, *args|
    arguments = args.join(' ').match(/\{(.+)\} \{(.+)\}/)
    next 'Too few arguments or incorrect syntax for command `addAlias`!' unless arguments

    role_name = arguments[1]
    role_alias = arguments[2]
    @assignable_roles_store.transaction do
      begin
        role_id = event.server.roles.find { |role| role.name.casecmp(role_name).zero? }.id
      rescue StandardError
        event.respond "The role you want to add an alias for doesn't exist."
        return
      end
      unless @assignable_roles_store[event.server.id][:self_assigning_roles].include?(role_id)
        event.respond "The role you want to add an alias for isn't self-assignable."\
            ' Please make it self assignable first, and then add an alias.'
        return
      end
      if @assignable_roles_store[event.server.id][:aliases].keys.include?(role_alias)
        event.respond 'That alias already exists.'
        event.message.delete
        return
      end
      @assignable_roles_store[event.server.id][:aliases][role_alias] = role_id

      event.message.react(EmojiTranslator.name_to_unicode('checkmark'))
    end
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    min_args: 1,
    usage: '.removeAlias roleAlias',
    description: 'Removes an alias for an existing role.'
  }
  command :removeAlias, attrs do |event, *args|
    role_alias = args.join(' ').downcase
    @assignable_roles_store.transaction do
      role_id = @assignable_roles_store[event.server.id][:aliases].delete(role_alias)
      if role_id
        event.message.react(EmojiTranslator.name_to_unicode('checkmark'))
      else
        event.send_temporary_message "Alias \"#{role_alias}\" doesn't exist.", 10
      end
    end
  end

  attrs = {
    usage: '.aliases',
    description: 'A list of all available aliases.'
  }
  command :aliases, attrs do |event|
    @assignable_roles_store.transaction do
      message = event.channel.send_embed do |embed|
        embed.title = 'All available aliases'

        role_ids = @assignable_roles_store[event.server.id][:aliases].values.uniq
        role_ids.each do |role_id|
          embed.add_field(
            name: id_to_rolename(event.server, role_id),
            value: @assignable_roles_store[event.server.id][:aliases].map { |k, v| v == role_id ? "• #{k}" : nil }.compact.join("\n")
          )
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

  command :refreshRoles do |event|
    refresh_roles(event, event.server)
  end

  def self.init_role_message(event)
    store = @assignable_roles_store
    event.bot.servers.each_value do |server|
      t = Thread.new do
        target_channel = 0
        @mutex.synchronize do
          store.transaction do
            target_channel = id_to_channel(server, store[server.id][:assignment_channel])
          end
        end

        if bot_messages = target_channel.history(100).select { |m| m.user.id == 346043915142561793 }
          bot_messages.each(&:delete)
        end
        send_role_message(event, server, target_channel)
      end
      t.abort_on_exception = true
    end
  end

  def self.refresh_reactions(event, server)
    store = @assignable_roles_store
    t = Thread.new do
      target_channel = 0
      server_roles = []
      @mutex.synchronize do
        store.transaction do
          target_channel = id_to_channel(server, store[server.id][:assignment_channel])
          server_roles = @assignable_roles_store[server.id][:self_assigning_roles]
        end
      end

      if message = target_channel.history(100).find { |m| m.user.id == 346043915142561793 }
        begin
          message.delete_all_reactions
          server_roles.length.times do |i|
            message.react(EmojiTranslator.name_to_emoji(i.to_s))
          end
        rescue StandardError
          # log_channel = id_to_channel(server, @assignable_roles_store[server.id][:log_channel])
          # log_channel.send_message 'No self-assignable roles. Add some with `.addToSelfAssign <roleName>`'if log_channel
          next
        end
      else
        refresh_roles(event, server)
      end
      t.abort_on_exception = true
    end
  end

  def self.refresh_roles(event, server)
    store = @assignable_roles_store
    Thread.new do
      target_channel = 0
      @mutex.synchronize do
        store.transaction do
          target_channel = id_to_channel(server, store[server.id][:assignment_channel])
        end
      end

      if (bot_messages = target_channel.history(100).select { |m| m.user.id == 346043915142561793 })
        bot_messages.each(&:delete)
      end
      send_role_message(event, server, target_channel)
    end
    nil
  end

  private_class_method def self.send_role_message(event, server, target_channel)
    server_roles = []
    messages = []
    @mutex.synchronize do
      @assignable_roles_store.transaction do
        server_roles = @assignable_roles_store[server.id][:self_assigning_roles]
        begin
          messages[0] = target_channel.send_embed do |embed|
            field_value = ''
            server_roles.each_with_index do |role, i|
              field_value << "• #{id_to_rolename(server, role)}\t[#{EmojiTranslator.name_to_emoji(i.to_s)}]\n\n"
            end
            embed.add_field(name: 'All roles you can assign to yourself.', value: field_value)
            embed.timestamp = Time.now
          end
        rescue StandardError
          log_channel = id_to_channel(server, @assignable_roles_store[server.id][:log_channel])
          log_channel.send_message 'No self-assignable roles. Add some with `.addToSelfAssign <roleName>`'if log_channel
          return
        end
      end
    end

    message = messages[0]

    server_roles.length.times do |i|
      message.react(EmojiTranslator.name_to_emoji(i.to_s))
    end

    event.bot.add_await(:"assignment_message_#{message.id}", Discordrb::Events::ReactionAddEvent) do |reaction_event|
      next false unless reaction_event.class == Discordrb::Events::ReactionAddEvent
      next false if reaction_event.user.id == 346043915142561793
      next false unless (reaction_event.message.id == message.id)
      role_id = emoji_to_role_id(server, reaction_event.emoji.name)
      next false unless role_id
      user = reaction_event.user.on(reaction_event.channel.server)
      Thread.new do
        @mutex.synchronize do
          @assignable_roles_store.transaction do
            add_role_to_user(event, user, server, role_id)
          end
        end
      end
      false
    end
  end

  private_class_method def self.emoji_to_role_id(server, emoji)
    role_id = nil
    t = Thread.new do
      @mutex.synchronize do
        @assignable_roles_store.transaction do
          11.times do |i|
            if emoji == EmojiTranslator.name_to_emoji(i.to_s)
              role_id = @assignable_roles_store[server.id][:self_assigning_roles][i]
            end
          end
        end
      end
      role_id
    end
    t.value
  end

  private_class_method def self.add_role_to_user(event, user, server, role_id)
    user_roles = []
    user.roles.each do |role|
      user_roles << role.id
    end
    # Return if the user already has the role he wants to give himself.
    return if user_roles.include?(role_id)

    delete_existing_roles(user, server, @assignable_roles_store[server.id][:self_assigning_roles], user_roles)
    user.add_role(role_id)
    # event.message.react(EmojiTranslator.name_to_unicode('checkmark'))
    log_channel = @assignable_roles_store[server.id][:log_channel]
    event.bot.channel(log_channel).send_message("#{user.distinct} gave himself the role \"#{id_to_rolename(server, role_id)}\".")
  end

  private_class_method def self.id_to_rolename(server, role_id)
    server.roles.find { |role| role.id == role_id }.name
  end

  private_class_method def self.id_to_channel(server, channel_id)
    server.channels.find { |channel| channel.id == channel_id }
  end

  private_class_method def self.role_alias_to_id(event, role_alias)
    @assignable_roles_store[event.server.id][:aliases][role_alias]
  end

  private_class_method def self.delete_existing_roles(user, server, assignable_roles, user_roles)
    assignable_roles.each do |role|
      if user_roles.include?(role)
        user.remove_role(server.roles.find { |s_role| s_role.id == role })
        sleep 0.1
      end
    end
  end
end
