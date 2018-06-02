require_relative 'join_leave_messages'
require_relative '../lib/role_message'

# Sets up and resets a whole bunch of stuff automatically
module ServerSystem
  extend Discordrb::EventContainer
  extend self

  # Setting things up for every server the bot is on on startup.
  ready do |event|
    SHRK.servers.each_value do |server|
      Thread.new do
        create_server_table(server.id)
        DB.init_default_values(server)
        init_permissions(server)

        message = RoleMessage.send(server)
        RoleMessage.add_role_await(server, message)
      end
    end

    SHRK.game = 'help | .prefix'
    # Uncomment before pushing!
    # SHRK.profile.username = 'shrkbot'
  end

  server_create do |event|
    # Set up everything for the server the bot just joined.
    create_server_table(event.server.id)
    DB.init_default_values(event.server)
    init_permissions(event.server)
  end

  server_delete do |event|
    # Clean up the database when the bot gets kicked from a server.
    DB.delete_server_values(event.server.id)
  end

  private

  # Sets up  the staff role for a given server.
  def init_permissions(server)
    SHRK.set_role_permission(server.roles.find { |role| role.name == 'BotCommand' }.id, 1)
  rescue StandardError
    # If it doesn't find the BotCommand role, it creates it.
    bot_command = server.create_role
    bot_command.name = 'BotCommand'
    LOGGER.log "I went ahead and created a 'BotCommand' role on '#{server.name}'. "\
      "Since that's how I know who may use staff commands, you might want to move it up a bit."

    init_permissions(server) # Needed so the permission level is actually set.
  end

  def create_server_table(server_id)
    attrs = {
      roles: :bigint,
      log_channel: :bigint,
      message_channel: :bigint,
      role_message_id: :bigint,
      assignment_channel: :bigint,
      join_message: :text,
      leave_message: :text,
      prefix: String
    }
    DB.create_table("shrk_server_#{server_id}".to_sym, attrs)
  end
end
