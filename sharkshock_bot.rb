require 'yaml'
require 'discordrb'
require 'yaml/store'

require_relative 'lib/emojis'
require_relative 'lib/database'
require_relative 'lib/reactions'
require_relative 'lib/charts/chart'

require_relative 'modules/mentions'
require_relative 'modules/misc_commands'
require_relative 'modules/server_system'
require_relative 'modules/chart_commands'
require_relative 'modules/join_leave_messages'
require_relative 'modules/self_assigning_roles'

# Bot inv: https://discordapp.com/oauth2/authorize?&client_id=346043915142561793&scope=bot&permissions=2146958591

# TODO: Improve .help (split normal / staff commands)
# TODO: Upgrade from YAML files to MySQL database
# TODO: Logger class

login = YAML.load_file('.login')
$bot_id = login[:client_id]

# Initiates connection to the database
print 'Initiating database connection...'
DB = Database.new(
  server: login[:server_name], # Delete if ran on the same server like the database
  username: login[:username],
  server_password: login[:server_password], # Delete if ran on the same server like the database
  db_name: login[:db_name],
  db_password: login[:db_password]
)
puts 'done!'

BOT = Discordrb::Commands::CommandBot.new(
  token: login[:token],
  client_id: $bot_id,
  prefix: '.',
  help_command: :help
)

BOT.include! Mentions
BOT.include! ServerSystem
BOT.include! MiscCommands
BOT.include! ChartCommands
BOT.include! JoinLeaveMessages
BOT.include! SelfAssigningRoles

at_exit do
  DB.close
  BOT.stop
end

BOT.run
