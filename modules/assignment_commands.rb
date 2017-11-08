# Commands to interact with RoleMessage
module AssignmentCommands
  extend Discordrb::Commands::CommandContainer

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: '.setAssignmentChannel <channelName>',
    description: 'Sets the channel where the bot displays the role assign message.',
    min_args: 1
  }
  # This is the manual setter, ServerSystem attempts to assign a default value when initializing.
  command :setAssignmentChannel, attrs do |event, *args|
    channel = event.server.channels.find { |s_channel| s_channel.name.casecmp?(args.join(' ')) }
    next "That channel doesn't exist." unless channel

    DB.update_value("ssb_server_#{event.server.id}".to_sym, :assignmet_channel, channel.id)
    # Automatically creates the new role-assignment message when you change the channel
    RoleMessage.send(channel)
    event.respond 'The new role-assignment message has been created, please delete the old one manually.'
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: '.addToSelfAssign <roleName>',
    description: 'Adds a role to the list of self-assignable roles.',
    min_args: 1
  }
  command :addToSelfAssign, attrs do |event, *args|
    role = event.server.roles.find { |s_role| s_role.name.casecmp?(args.join(' ')) }
    next "I couldn't find the role you were looking for." unless role

    # Roles higher than the bot's highest can't be made self-assignable.
    if role.position >= SSB.profile.on(event.server).roles.sort_by(&:position).last.position
      event.send_temporary_message "That role's rank is too high.", 10
      next
    end

    if DB.unique_insert("ssb_server_#{event.server.id}".to_sym, :assignable_roles, role.id)
      Reactions.confirm(event.message)
    else
      event.send_temporary_message('That role is already self assignable.', 10)
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
    role = event.server.roles.find { |s_role| s_role.name.casecmp?(args.join(' ')) }.id
    next "I couldn't find the role you were looking for." unless role

    if DB.delete_value("ssb_server_#{event.server.id}".to_sym, :assignable_roles, role.id)
      Reactions.confirm(event.message)
    else
      event.send_temporary_message("The role #{args.join(' ').downcase} isn't self-assignable.", 10)
    end
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: '.refreshRoles',
    description: 'Triggers a manual refresh for the role message.'
  }
  command :refreshRoles, attrs do |event|
    RoleMessage.send!(event.server)
  end

  attrs = {
    usage: '.roles',
    description: 'Points you to the channel where you can assign roles to yourself.'
  }
  command :roles, attrs do |event|
    channel_id = DB.read_value("ssb_server_#{event.server.id}", :assignment_channel)
    "In the channel <##{channel_id}> you can find the roles you can assign to yourself."
  end
end
