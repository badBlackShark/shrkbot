require 'yaml'
require 'discordrb'
require 'yaml/store'

require_relative 'lib/emojis'
require_relative 'lib/database'
require_relative 'lib/reactions'
require_relative 'lib/ssb_logger'
require_relative 'lib/charts/chart'

require_relative 'modules/mentions'
require_relative 'modules/misc_commands'
require_relative 'modules/server_system'
require_relative 'modules/chart_commands'
require_relative 'modules/logger_commands'
require_relative 'modules/join_leave_messages'
require_relative 'modules/assignment_commands'

# Bot inv: https://discordapp.com/oauth2/authorize?&client_id=346043915142561793&scope=bot&permissions=2146958591

# TODO: Improve .help (split normal / staff commands)
# TODO: Upgrade from YAML files to MySQL database
# TODO: Maybe look into rufus-scheduler for scheduling

login = YAML.load_file('.login')
BOT_ID = login[:client_id]

# Create the directory that charts get saved in.
Dir.mkdir('images') unless File.exist?('images')

print 'Initiating database connection...'
DB = Database.new(
  server: login[:server_name], # Delete if ran on the same server as the database
  username: login[:username],
  server_password: login[:server_password], # Delete if ran on the same server as the database
  db_name: login[:db_name],
  db_password: login[:db_password]
)
puts 'done!'

SSB = Discordrb::Commands::CommandBot.new(
  token: login[:token],
  client_id: BOT_ID,
  prefix: '.',
  help_command: :help
)

LOGGER = SSBLogger.new

SSB.include! Mentions
SSB.include! ServerSystem
SSB.include! MiscCommands
SSB.include! ChartCommands
SSB.include! LoggerCommands
SSB.include! JoinLeaveMessages
SSB.include! AssignmentCommands

at_exit do
  DB.close
  SSB.stop
end

SSB.run
