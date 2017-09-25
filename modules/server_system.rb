require_relative 'self_assigning_roles'
require_relative 'join_leave_messages'

module ServerSystem
  extend Discordrb::EventContainer

  ready do |event|
    event.bot.servers.each_value do |server|
      init event, server
    end
    SelfAssigningRoles.init_role_message event
    # event.bot.game = ".help | NEW PREFIX!"
    refresh_reactions_cycle(event)
  end

  server_create do |event|
    init(event, event.server)
  end

  server_delete do |event|
    delete_assigns(event.server)
    delete_messages(event.server)
  end

  def self.init(event, server)
    init_assigns(server)
    init_messages(server)
    init_permissions(event, server)
  end

  private_class_method def self.init_assigns(server)
    SelfAssigningRoles.assignable_roles_store.transaction do
      assignment_channel = server.channels.find { |channel| channel.name.include?('rules') }
      assignment_channel ||= server.channels.sort_by { |c| [c.position, c.id] }[1]

      log_channel = server.channels.find { |channel| channel.name =~ /(mod|admin|staff|log)/i }
      log_id = log_channel.id if log_channel

      SelfAssigningRoles.assignable_roles_store[server.id] ||= {
        self_assigning_roles: [],
        aliases: {},
        log_channel: log_id,
        assignment_channel: assignment_channel.id
      }
    end
  end

  private_class_method def self.init_messages(server)
    JoinLeaveMessages.message_store.transaction do
      JoinLeaveMessages.message_store[server.id] ||= {
        join_message: [],
        leave_message: []
      }
    end
  end

  private_class_method def self.init_permissions(event, server)
    event.bot.set_role_permission(server.roles.find { |role| role.name == 'BotCommand' }.id, 1)
  rescue StandardError
    bot_command = server.create_role
    bot_command.name = 'BotCommand'
    server.owner.pm "I went ahead and created a 'BotCommand' role on '#{server.name}'. "\
          "Since that's how I know who may use staff commands, you might want to move it up a bit."
    init_permissions(event, server)
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
    sleep 86400
    event.bot.servers.each_value do |server|
      SelfAssigningRoles.refresh_reactions(event, server)
    end
    refresh_reactions_cycle(event)
  end
end
