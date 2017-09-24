require 'discordrb'
require 'yaml'
require 'yaml/store'

require_relative 'lib/emoji_translator'
require_relative 'modules/server_system'
require_relative 'modules/misc_commands'
require_relative 'modules/mention_system'
require_relative 'modules/join_leave_messages'
require_relative 'modules/self_assigning_roles'

# Bot inv: https://discordapp.com/oauth2/authorize?&client_id=346043915142561793&scope=bot&permissions=2146958591

login = YAML.load_file('.login')

bot = Discordrb::Commands::CommandBot.new(
    token: login[:token],
    client_id: login[:client_id],
    prefix: '.',
    help_command: :help,
    advanced_functionality: true
)

bot.include! ServerSystem
bot.include! MiscCommands
bot.include! MentionSystem
bot.include! JoinLeaveMessages
bot.include! SelfAssigningRoles

bot.run
