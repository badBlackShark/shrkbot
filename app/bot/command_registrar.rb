# frozen_string_literal: true

class CommandRegistrar
  def initialize(bot, commands:, define_commands: true)
    @bot = bot
    @commands = commands.select(&:registrable)
    @define_commands = define_commands
  end

  attr_reader :bot, :commands

  def register_all
    commands.each do |klass|
      attach(klass)
      attach_autocomplete(klass) if klass.autocomplete?
    end

    define_global if @define_commands
  end

  private

  def define_global
    return if Rails.env.development?

    global_payloads = commands
      .select { |klass| klass.registration.global? }
      .map { |klass| CommandPayload.new(klass.registration).to_h }

    Discordrb::API::Application.bulk_overwrite_global_commands(
      bot.token,
      bot.profile.id,
      global_payloads
    )
  end

  def attach(klass)
    bot.application_command(klass.command_name) { |event| klass.dispatch(event) }
  end

  def attach_autocomplete(klass)
    bot.autocomplete(nil, command_name: klass.command_name) { |event| klass.dispatch_autocomplete(event) }
  end
end
