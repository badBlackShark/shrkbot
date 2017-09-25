require 'thread'

# Allows users to assign certain, preset roles to themselves via reactions to a message in a preset channel.
# Warning, this module requires ServerSystem to function as intended, since that's responsible for setting up
# and resetting certain things.
# This also logs role assignments in a designated channel.
module SelfAssigningRoles
  extend Discordrb::Commands::CommandContainer

  # TODO: Remove init_role_message redundancy. ServerSystem.init; refresh_roles do the same thing.

  # Getter for the assignables store
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
  # This is the manual setter, ServerSystem attempts to assign a default value when initializing.
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
  # This is the manual setter, ServerSystem attempts to assign a default value when initializing.
  command :setAssignmentChannel, attrs do |event, *args|
    @assignable_roles_store.transaction do
      channel = event.server.channels.find { |s_channel| s_channel.name.casecmp(args.join(' ')).zero? }
      next "That channel doesn't exist." unless channel

      @assignable_roles_store[event.server.id][:assignment_channel] = channel.id
      event.message.react(EmojiTranslator.name_to_unicode('checkmark'))
      # Automatically creates the new role-assignment message when you change the channel
      refresh_roles(event, event.server)
      event.respond "The new role message has been created, please delete the old one manually."
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

      # Roles higher than the bot's highest can't be made self-assignable.
      if role.position >= event.bot.profile.on(event.server).roles.sort_by { |r| [r.position, r.id] }.last.position
        event.send_temporary_message "That role's rank is too high.", 10
        event.message.delete
        next
      end

      if @assignable_roles_store[event.server.id][:self_assigning_roles].include?(role.id)
        event.send_temporary_message "The role #{args.join(' ')} is already self-assignable.", 10
        event.message.delete
        next
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
        event.send_temporary_message "The role #{args.join(' ').downcase} isn't self-assignable.", 10
        event.message.delete
        next
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

  # Allows for a manual refresh, e.g. after adding new self-assignable roles.
  command :refreshRoles do |event|
    refresh_roles(event, event.server)
  end

  # All of these functions work multithreaded. This allows the bot to initialize the message etc. in every
  # server it's in at once. Mutexes so there are no nested transactions.

  # Sends the role-assignment message in every server the bot is in. Called on startup.
  def self.init_role_message(event)
    store = @assignable_roles_store
    event.bot.servers.each_value do |server|
      Thread.new do
        target_channel = nil
        @mutex.synchronize do
          store.transaction do
            target_channel = id_to_channel(server, store[server.id][:assignment_channel])
          end
        end

        # This assumes that the only permanent message the bot's supposed to have in that channel is the one for
        # role assignments. Will need to be changed in the future (e.g. storing message ID)
        if bot_messages = target_channel.history(100).select { |m| m.user.id == 346043915142561793 }
          bot_messages.each(&:delete)
        end
        send_role_message(event, server, target_channel)
      end
    end
  end

  # Deletes all the reactions from the role assignment message, and reacts with the relevant reactions again.
  # Called every 24 hours by ServerSystem for clean reactions.
  def self.refresh_reactions(event, server)
    store = @assignable_roles_store
    Thread.new do
      target_channel = 0
      server_roles = []
      @mutex.synchronize do
        store.transaction do
          target_channel = id_to_channel(server, store[server.id][:assignment_channel])
          server_roles = @assignable_roles_store[server.id][:self_assigning_roles]
        end
      end

      # This assumes that the relevant message is the bot's newest in that channel. Will need to be changed.
      if message = target_channel.history(100).find { |m| m.user.id == 346043915142561793 }
        begin
          message.delete_all_reactions
          server_roles.length.times do |i|
            message.react(EmojiTranslator.name_to_emoji(i.to_s))
          end
        rescue StandardError
          log_channel = id_to_channel(server, @assignable_roles_store[server.id][:log_channel])
          log_channel.send_message 'An error has occured while refreshing the reactions. Please call `.refreshRoles`.'if log_channel
          next
        end
      else
        # If the message doesn't exist, send it.
        refresh_roles(event, server)
      end
    end
  end

  # Works like init_role_message, but only for one server. [Redundant!]
  def self.refresh_roles(event, server)
    store = @assignable_roles_store
    Thread.new do
      target_channel = 0
      @mutex.synchronize do
        store.transaction do
          target_channel = id_to_channel(server, store[server.id][:assignment_channel])
        end
      end

      # This assumes that the only permanent message the bot's supposed to have in that channel is the one for
      # role assignments. Will need to be changed in the future (e.g. storing message ID)
      if (bot_messages = target_channel.history(100).select { |m| m.user.id == 346043915142561793 })
        bot_messages.each(&:delete)
      end
      send_role_message(event, server, target_channel)
    end
    nil
  end

  # Creates the actual message, and adds the await.
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

    message = messages[0] # Not clean, but I couldn't get it to work otherwise.

    server_roles.length.times do |i|
      message.react(EmojiTranslator.name_to_emoji(i.to_s))
    end

    event.bot.add_await(:"assignment_message_#{message.id}", Discordrb::Events::ReactionAddEvent) do |reaction_event|
      # Reaction events are broken, needs the check to make sure it's actually the event I want.
      next false unless reaction_event.class == Discordrb::Events::ReactionAddEvent
      # Don't react to the bot's own reactions
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

  # Translates an emoji on the reaction message into an actual role id.
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

  # Adds a role to a user. Include a removal of all other self-assignable roles.
  private_class_method def self.add_role_to_user(event, user, server, role_id)
    user_roles = []
    user.roles.each do |role|
      user_roles << role.id
    end
    # Return if the user already has the role he wants to give himself.
    return if user_roles.include?(role_id)

    delete_existing_roles(user, server, @assignable_roles_store[server.id][:self_assigning_roles], user_roles)
    user.add_role(role_id)
    user.pm("I assigned the role \"#{id_to_rolename(serverm role_id)}\" to you on \"#{server.name}\"")
    log_channel = @assignable_roles_store[server.id][:log_channel]
    event.bot.channel(log_channel).send_message("#{user.distinct} gave himself the role \"#{id_to_rolename(server, role_id)}\".")
  end

  # Translates a role ID to the name of that role on a given server.
  private_class_method def self.id_to_rolename(server, role_id)
    server.roles.find { |role| role.id == role_id }.name
  end

  # Translates a channel ID to a channel object.
  private_class_method def self.id_to_channel(server, channel_id)
    server.channels.find { |channel| channel.id == channel_id }
  end

  # Deletes all self-assignable roles a user has.
  private_class_method def self.delete_existing_roles(user, server, assignable_roles, user_roles)
    assignable_roles.each do |role|
      if user_roles.include?(role)
        user.remove_role(server.roles.find { |s_role| s_role.id == role })
        sleep 0.1 # Required so everything works as intended.
      end
    end
  end
end
