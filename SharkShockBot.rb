require 'discordrb'
require 'yaml'
require 'yaml/store'

require_relative 'lib/EmojiTranslator'
require_relative 'modules/ServerSystem'
require_relative 'modules/MiscCommands'
require_relative 'modules/MentionSystem'
require_relative 'modules/JoinLeaveMessages'
require_relative 'modules/SelfAssigningRoles'

#Bot inv: https://discordapp.com/oauth2/authorize?&client_id=346043915142561793&scope=bot&permissions=2146958591

login = YAML.load_file('.login')
$assignableRolesStore = YAML::Store.new "assignables.yaml"
$messageStore = YAML::Store.new "messages.yaml"

bot = Discordrb::Commands::CommandBot.new(
    token: login[:token],
    client_id: login[:client_id],
    prefix: '.',
    help_command: (:help),
    advanced_functionality: true
)

bot.include! ServerSystem
bot.include! MiscCommands
bot.include! MentionSystem
bot.include! JoinLeaveMessages
bot.include! SelfAssigningRoles

bot.run
