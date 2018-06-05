require 'yaml'
require 'discordrb'
require 'yaml/store'

require_relative 'lib/icons'
require_relative 'lib/emojis'
require_relative 'lib/database'
require_relative 'lib/webhooks'
require_relative 'lib/reactions'
require_relative 'lib/shrk_logger'
require_relative 'lib/charts/chart'

require_relative 'modules/help'
require_relative 'modules/todo'
require_relative 'modules/update'
require_relative 'modules/mentions'
require_relative 'modules/prefixes'
require_relative 'modules/roulette'
require_relative 'modules/fun_stuff'
require_relative 'modules/reminders'
require_relative 'modules/moderation'
require_relative 'modules/link_removal'
require_relative 'modules/misc_commands'
require_relative 'modules/server_system'
require_relative 'modules/chart_commands'
require_relative 'modules/logger_commands'
require_relative 'modules/webhook_commands'
require_relative 'modules/assignment_commands'
require_relative 'modules/join_leave_messages'

# Bot inv: https://discordapp.com/oauth2/authorize?&client_id=346043915142561793&scope=bot&permissions=2146958591

# TODO: Improve database column types

# Create the directory that charts get saved in.
Dir.mkdir('images') unless File.exist?('images')

login = YAML.load_file('.login')
BOT_ID = login[:client_id]

print 'Initializing database connection...'
DB = Database.new(
  server: login[:server_name], # Delete if ran on the same server as the database
  username: login[:username],
  server_password: login[:server_password], # Delete if ran on the same server as the database
  db_name: login[:db_name],
  db_password: login[:db_password]
)
puts 'done!'

not_ready = true

# Using an in-memory hash because the lookup times are so much faster.
# Obviously, the values will still be stored in the database for persistency.
$prefixes = {}
prefix_proc = proc do |message|
  next if not_ready || message.webhook?
  prefix = $prefixes[message.channel.server&.id] || '.'
  if message.content.start_with?(prefix)
    # Almost all commands crash if called in a PM, so let's disable that outright.
    if message.channel.private? && message.user.id != 94558130305765376
      message.channel.send "I'm sorry, I don't accept commands in PMs. Please try again in a server."
      next
    end
    # Converts the command to downcase, so commands are case-insensitive.
    message.content[prefix.size..-1].sub(/\w+/, &:downcase)
  end
end

SHRK = Discordrb::Commands::CommandBot.new(
  token: login[:token],
  client_id: BOT_ID,
  prefix: prefix_proc,
  help_command: false
)

# Deletes the role from the list of self-assignable roles if the role is deleted.
# Handler needs to be added manually, because the library does not have an abstract version.
block = proc do |event|
  DB.delete_value("shrk_server_#{event.server.id}".to_sym, :roles, event.id)
  RoleMessage.send!(event.server)
end
role_delete = Discordrb::Events::ServerRoleDeleteEventHandler.new({}, block)
SHRK.add_handler(role_delete)

LOGGER = SHRKLogger.new

SHRK.include! Help
SHRK.include! Todo
SHRK.include! Update
SHRK.include! Mentions
SHRK.include! Prefixes
SHRK.include! Roulette
SHRK.include! FunStuff
SHRK.include! Reminders
SHRK.include! Moderation
SHRK.include! LinkRemoval
SHRK.include! ServerSystem
SHRK.include! MiscCommands
SHRK.include! ChartCommands
SHRK.include! LoggerCommands
SHRK.include! WebhookCommands
SHRK.include! JoinLeaveMessages
SHRK.include! AssignmentCommands

# The general format dates & times should follow.
TIME_FORMAT = '%A, %d. %B, %Y at %-l:%M:%S%P %Z'.freeze

at_exit do
  Roulette.write_to_db
  DB.close
  SHRK.stop
end

# Initialize what doesn't require a gateway connection.
Todo.init

SHRK.run(:async)
SHRK.set_user_permission(94558130305765376, 2)

# Initialize everything that does require a gateway connection.
WH = Webhooks.new
LinkRemoval.init
Moderation.init
Reminders.init
Roulette.init

# Database might not exist yet, so just wait a moment.
sleep 2

SHRK.servers.each_value do |server|
  $prefixes[server.id] = DB.read_value("shrk_server_#{server.id}".to_sym, :prefix)
  Roulette.load_revolver(server.id)
  # Cache members.
  server.members
end

puts 'Setup completed.'
not_ready = false

SHRK.sync
