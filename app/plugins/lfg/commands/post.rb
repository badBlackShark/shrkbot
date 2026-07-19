# frozen_string_literal: true

module Lfg
  class Post < Bot::BaseCommand
    command_name :lfg
    description "Find people to play with — ping a game's role and let others join in."
    plugin :lfg

    options do |opts|
      opts.string("role", "The game role to look for", required: true, autocomplete: true)
      opts.string("message", "Optional note — what you're playing, the vibe, etc.", required: false)
      opts.string("starting_in", "Optional — schedule it, e.g. 30m, 2h, 1d (up to 30 days)", required: false)
    end

    def execute
      config = server_configuration
      return event.respond(content: "LFG isn't set up here.", ephemeral: true) unless config&.lfg_settings

      event.defer(ephemeral: true)
      outcome = Lfg::PostCreation.call(
        server_configuration: config,
        channel: event.channel,
        bot: event.bot,
        member: event.server.member(event.user.id),
        role_id: event.options["role"].to_i,
        message: event.options["message"],
        starting_in: event.options["starting_in"],
        mention_permission: event.interaction.application_permissions&.mention_everyone
      )
      event.edit_response(content: outcome.message)
    end

    def autocomplete
      event.respond(choices: role_choices)
    end

    private

    def server_configuration
      ServerConfiguration.find_by(discord_id: event.server.id)
    end

    def role_choices
      config = server_configuration
      return {} unless config&.lfg_settings

      typed = event.options["role"].to_s.downcase
      ids = config.lfg_settings.pingable_roles.pluck(:role_id)
      config.server_roles.where(discord_id: ids).pluck(:discord_id, :name)
        .select { |_id, name| typed.empty? || name.downcase.start_with?(typed) }
        .first(25)
        .to_h { |id, name| [name, id.to_s] }
    end
  end
end
