# Commands to interact with RoleMessage
module AssignmentCommands
  extend Discordrb::EventContainer
  extend Discordrb::Commands::CommandContainer
  extend self

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: 'setAssignmentChannel <channelName>',
    description: 'Sets the channel where the bot displays the role assign message.',
    min_args: 1
  }
  # This is the manual setter, ServerSystem attempts to assign a default value when initializing.
  command :setassignmentchannel, attrs do |event, *args|
    channel = event.server.channels.find { |s_channel| s_channel.name.casecmp?(args.join(' ')) }
    next "That channel doesn't exist." unless channel

    RoleMessage.role_message(event.server.id)&.delete

    DB.update_value("shrk_server_#{event.server.id}".to_sym, :assignment_channel, channel.id)
    Reactions.confirm(event.message)
    # Automatically creates the new role-assignment message when you change the channel
    RoleMessage.send(event.server)
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: 'addToSelfAssign <roleNames>',
    description: 'Adds as many roles to the list of self-assignable roles as you want.',
    min_args: 1
  }
  command :addtoselfassign, attrs do |event, *args|
    # Name of the role => successfully inserted
    roles = Hash[args.join(' ').split(', ').collect { |role_name| [role_name, false] }]
    roles.each_key do |role_name|
      response = insert_role(event, role_name)
      if response
        event.respond response
      else
        roles[role_name] = true
      end
    end

    response = roles.select { |_role_name, success| success }.keys.join('", "')

    unless response.empty?
      RoleMessage.send!(event.server)
      "Added the roles \"#{response}\" to the list of self-assignable roles."
    end
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: 'removeFromSelfAssign <roleName>',
    description: 'Removes as many roles from the list of self-assignable roles as you want.',
    min_args: 1
  }
  command :removefromselfassign, attrs do |event, *args|
    roles = Hash[args.join(' ').split(', ').collect { |role_name| [role_name, false] }]
    roles.each_key do |role_name|
      role = event.server.roles.find { |s_role| s_role.name.casecmp?(role_name) }
      if DB.delete_value("shrk_server_#{event.server.id}".to_sym, :roles, role.id)
        roles[role_name] = true
      else
        event.respond("The role \"#{role_name}\" isn't self-assignable.")
      end
    end

    response = roles.select { |_role_name, success| success }.keys.join('", "')

    unless response.empty?
      RoleMessage.send!(event.server)
      "Removed the roles \"#{response}\" from the list of self-assignable roles."
    end
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: 'refreshRoles',
    description: 'Triggers a manual refresh for the role message.'
  }
  command :refreshroles, attrs do |event|
    RoleMessage.send!(event.server)
  end

  attrs = {
    usage: 'roles',
    description: 'Points you to the channel where you can assign roles to yourself.'
  }
  command :roles, attrs do |event|
    channel_id = DB.read_value("shrk_server_#{event.server.id}".to_sym, :assignment_channel)
    "You can assign roles to yourself in <##{channel_id}>."
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: 'assignmentChannel?',
    description: 'Tells you what the assignment channel is, in case you forgot which one it was.'
  }
  command :assignmentchannel?, attrs do |event|
    assignment_channel = DB.read_value("shrk_server_#{event.server.id}".to_sym, :assignment_channel)
    next "The assignment channel is <##{assignment_channel}>." if assignment_channel

    'There is no assignment channel. Please set one by using the `setAssignmentChannel` command.'
  end

  private

  def insert_role(event, role_name)
    role = event.server.roles.find { |s_role| s_role.name.casecmp?(role_name) }
    return "I couldn't find the role \"#{role_name}\"." unless role

    # Roles higher than the bot's highest can't be made self-assignable.
    if role.position >= SHRK.profile.on(event.server).roles.sort_by(&:position).last.position
      return "The rank of the role \"#{role_name}\" is too high."
    end

    if DB.read_column("shrk_server_#{event.server.id}".to_sym, :roles).count > 26
      return 'There are too many self-assignable roles!'
    end

    !DB.unique_insert("shrk_server_#{event.server.id}".to_sym, :roles, role.id) && \
    "The role #{role_name} is already self-assignable."
  end
end
