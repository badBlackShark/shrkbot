# Pushes each command's definition to Discord and attaches its in-process
# handler. The bot is duck-typed (Discordrb::Bot): #register_application_command
# and #application_command. That boundary is the only Discord-touching part;
# everything deciding WHAT to register lives in BaseCommand.registration.
#
# ponytail: :guild commands all register to TEST_SERVER_ID for now. Per-server
# registration driven by plugin enable/disable is Phase 8 (Redis → job).
class CommandRegistrar
  # instant_global (dev): register :global commands to the test server too, so
  # they appear instantly. Global propagation takes up to ~1h, which is painful
  # for iteration. Such a registration is guild-scoped (server-only), so the DM
  # path of a global command still needs a real global registration (production).
  def initialize(bot, commands:, test_server_id: BotConfig.test_server_id, instant_global: false)
    @bot = bot
    @commands = commands.select(&:registrable)
    @test_server_id = test_server_id
    @instant_global = instant_global
  end

  attr_reader :bot, :commands, :test_server_id

  def register_all
    commands.each do |klass|
      next unless define(klass)

      attach(klass)
      attach_autocomplete(klass) if klass.autocomplete?
    end
  end

  private

  def define(klass)
    reg = klass.registration

    # A :guild command needs a server to register against. Without one it would
    # silently register GLOBALLY (up to ~1h to appear, no per-server toggle), so
    # skip + warn instead. In production :guild commands register per-server on
    # plugin enable (Phase 8); TEST_SERVER_ID is the local-testing stand-in.
    if !reg.global? && test_server_id.to_s.empty?
      Rails.logger.warn("[CommandRegistrar] skipping :guild command /#{reg.name} — TEST_SERVER_ID not set")
      return false
    end

    to_guild = !reg.global? || (@instant_global && test_server_id.present?)

    bot.register_application_command(
      reg.name,
      reg.description,
      server_id: to_guild ? test_server_id : nil,
      default_member_permissions: reg.permissions.presence,
      contexts: to_guild ? nil : reg.contexts,
      &reg.options_block
    )
    true
  end

  def attach(klass)
    bot.application_command(klass.command_name) { |event| klass.dispatch(event) }
  end

  def attach_autocomplete(klass)
    # discordrb's autocomplete(name) matches `name` against the focused OPTION,
    # not the command. Filter by command_name so it fires for the whole command
    # regardless of which option is focused.
    bot.autocomplete(nil, command_name: klass.command_name) { |event| klass.dispatch_autocomplete(event) }
  end
end
