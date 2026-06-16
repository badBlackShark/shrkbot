# For now all :guild commands register to TEST_SERVER_ID; per-server registration
# on plugin enable/disable is Phase 8.
class CommandRegistrar
  # instant_global (dev): register :global commands to the test server for instant
  # appearance — global propagation takes up to ~1h. Guild-scoped, so it can't
  # reach DMs; production registers them truly globally.
  def initialize(bot, commands:, instant_global: false)
    @bot = bot
    @commands = commands.select(&:registrable)
    @instant_global = instant_global
  end

  attr_reader :bot, :commands

  def register_all
    commands.each do |klass|
      next unless define(klass)

      attach(klass)
      attach_autocomplete(klass) if klass.autocomplete?
    end
  end

  private

  def test_server_id
    BotConfig.test_server_id
  end

  def define(klass)
    reg = klass.registration

    # Without a server, a :guild command would silently register globally — skip it.
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
    # discordrb's autocomplete(name) matches the focused OPTION, not the command —
    # filter by command_name instead.
    bot.autocomplete(nil, command_name: klass.command_name) { |event| klass.dispatch_autocomplete(event) }
  end
end
