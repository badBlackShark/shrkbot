require 'yaml'
require 'discordrb'
require 'yaml/store'

require_relative 'lib/emojis'
require_relative 'lib/database'
require_relative 'lib/reactions'
require_relative 'lib/shrk_logger'
require_relative 'lib/charts/chart'

require_relative 'modules/help'
require_relative 'modules/prefixes'
require_relative 'modules/mentions'
require_relative 'modules/server_system'
require_relative 'modules/misc_commands'
require_relative 'modules/chart_commands'
require_relative 'modules/logger_commands'
require_relative 'modules/join_leave_messages'
require_relative 'modules/assignment_commands'

# Bot inv: https://discordapp.com/oauth2/authorize?&client_id=346043915142561793&scope=bot&permissions=2146958591

# TODO: .todo and .reminder with rufus scheduler (v1.3.1)

# Create the directory that charts get saved in.
Dir.mkdir('images') unless File.exist?('images')

login = YAML.load_file('.login')
BOT_ID = login[:client_id]

print 'Initiating database connection...'
DB = Database.new(
  server: login[:server_name], # Delete if ran on the same server as the database
  username: login[:username],
  server_password: login[:server_password], # Delete if ran on the same server as the database
  db_name: login[:db_name],
  db_password: login[:db_password]
)
puts 'done!'

# Using a hash because the lookup times are so much faster.
# Obviously, the values will still be stored in the database for persistency.
$prefixes = {}
prefix_proc = proc do |message|
  prefix = $prefixes[message.channel.server&.id] || '.'
  message.content[prefix.size..-1] if message.content.start_with?(prefix)
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
SHRK.include! Prefixes
SHRK.include! Mentions
SHRK.include! ServerSystem
SHRK.include! MiscCommands
SHRK.include! ChartCommands
SHRK.include! LoggerCommands
SHRK.include! JoinLeaveMessages
SHRK.include! AssignmentCommands

at_exit do
  DB.close
  SHRK.stop
end

SHRK.run(:async)

# Database might not exist yet, so just wait a moment.
sleep 2

SHRK.servers.each_value do |server|
  $prefixes[server.id] = DB.read_value("shrk_server_#{server.id}".to_sym, :prefix)
end

SHRK.sync
