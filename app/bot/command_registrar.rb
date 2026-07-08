# frozen_string_literal: true

class CommandRegistrar
  def initialize(bot, commands:, instant_global: false, define_commands: true)
    @bot = bot
    @commands = commands.select(&:registrable)
    @instant_global = instant_global
    @define_commands = define_commands
  end

  attr_reader :bot, :commands

  def register_all
    commands.each do |klass|
      next unless registrable_here?(klass)

      define(klass) if @define_commands
      attach(klass)
      attach_autocomplete(klass) if klass.autocomplete?
    end
  end

  private

  def test_server_id
    BotConfig.test_server_id
  end

  def registrable_here?(klass)
    reg = klass.registration
    return true if reg.global? || test_server_id.present?

    Rails.logger.warn("[CommandRegistrar] skipping :guild command /#{reg.name} — TEST_SERVER_ID not set")
    false
  end

  def define(klass)
    reg = klass.registration
    to_guild = !reg.global? || (@instant_global && test_server_id.present?)

    bot.register_application_command(
      reg.name,
      reg.description,
      server_id: to_guild ? test_server_id : nil,
      default_member_permissions: reg.permissions.presence,
      contexts: to_guild ? nil : reg.contexts,
      type: reg.type,
      &reg.options_block
    )
  end

  def attach(klass)
    bot.application_command(klass.command_name) { |event| klass.dispatch(event) }
  end

  def attach_autocomplete(klass)
    bot.autocomplete(nil, command_name: klass.command_name) { |event| klass.dispatch_autocomplete(event) }
  end
end
