# Pushes each command's definition to Discord and attaches its in-process
# handler. The bot is duck-typed (Discordrb::Bot): #register_application_command
# and #application_command. That boundary is the only Discord-touching part;
# everything deciding WHAT to register lives in BaseCommand.registration.
#
# ponytail: :guild commands all register to TEST_SERVER_ID for now. Per-server
# registration driven by plugin enable/disable is Phase 8 (Redis → job).
class CommandRegistrar
  def initialize(bot, commands:, test_server_id: BotConfig.test_server_id)
    @bot = bot
    @commands = commands.select(&:registrable)
    @test_server_id = test_server_id
  end

  attr_reader :bot, :commands, :test_server_id

  def register_all
    commands.each do |klass|
      define(klass)
      attach(klass)
    end
  end

  private

  def define(klass)
    reg = klass.registration
    bot.register_application_command(
      reg.name,
      reg.description,
      server_id: reg.global? ? nil : test_server_id,
      default_member_permissions: reg.permissions.presence,
      contexts: reg.contexts,
      &reg.options_block
    )
  end

  def attach(klass)
    bot.application_command(klass.command_name) { |event| klass.dispatch(event) }
  end
end
