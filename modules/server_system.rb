require_relative 'self_assigning_roles'
require_relative 'join_leave_messages'

# Sets up and resets a whole bunch of stuff automatically
module ServerSystem
  extend Discordrb::EventContainer

  # Setting things up for every server the bot is on on startup.
  ready do |event|
    event.bot.servers.each_value do |server|
      init(event, server)
    end
    # Create & send the role assignment messages.
    SelfAssigningRoles.init_role_message(event)
    event.bot.game = ".help | NEW PREFIX!"
    # Start the 24 hour cycle of refreshing the reactions on the role assignment messages.
    refresh_reactions_cycle(event)
  end

  server_create do |event|
    # Set up everything for the server the bot just joined.
    init(event, event.server)
  end

  server_delete do |event|
    # Clean up the .yaml files when the bot gets kicked from a server.
    delete_assigns(event.server)
    delete_messages(event.server)
  end

  def self.init(event, server)
    # Sets up the stores and the staff role for a given server.
    init_assigns(server)
    init_messages(server)
    init_permissions(event, server)
  end

  private_class_method def self.init_assigns(server)
    SelfAssigningRoles.assignable_roles_store.transaction do
      # Assignment channel defaults to the rules channel...
      assignment_channel = server.channels.find { |channel| channel.name.include?('rules') }
      # ...or the top channel, if there's no rules channel.
      assignment_channel ||= server.channels.sort_by { |c| [c.position, c.id] }[1]

      # Log channel defaults to whatever convenient non-public channel it can find.
      log_channel = server.channels.find { |channel| channel.name =~ /(mod|admin|staff|log)/i }
      log_id = log_channel.id if log_channel

      # Create the section for the server in the file, if it doesn't exist yet.
      SelfAssigningRoles.assignable_roles_store[server.id] ||= {
        self_assigning_roles: [],
        log_channel: log_id,
        assignment_channel: assignment_channel.id
      }
    end
  end

  private_class_method def self.init_messages(server)
    JoinLeaveMessages.message_store.transaction do
      # Create the section for the server in the file, if it doesn't exist yet.
      JoinLeaveMessages.message_store[server.id] ||= {
        join_message: [],
        leave_message: []
      }
    end
  end

  private_class_method def self.init_permissions(event, server)
    event.bot.set_role_permission(server.roles.find { |role| role.name == 'BotCommand' }.id, 1)
  rescue StandardError
    # If it doesn't find the BotCommand role, it creates it.
    bot_command = server.create_role
    bot_command.name = 'BotCommand'
    server.owner.pm "I went ahead and created a 'BotCommand' role on '#{server.name}'. "\
          "Since that's how I know who may use staff commands, you might want to move it up a bit."
    init_permissions(event, server) # Needed so the permission level is actually set.
  end

  private_class_method def self.delete_assigns(server)
    SelfAssigningRoles.assignable_roles_store.transaction do
      SelfAssigningRoles.assignable_roles_store.delete(server.id)
    end
  end

  private_class_method def self.delete_messages(server)
    JoinLeaveMessages.message_store.transaction do
      JoinLeaveMessages.message_store.delete(server.id)
    end
  end

  private_class_method def self.refresh_reactions_cycle(event)
    sleep 86400 # 24 hours
    event.bot.servers.each_value do |server|
      SelfAssigningRoles.refresh_reactions(event, server)
    end
    refresh_reactions_cycle(event)
  end
end
