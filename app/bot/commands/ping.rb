# frozen_string_literal: true

module Commands
  class Ping < BaseCommand
    command_name :ping
    description "Check that the bot is online and responding."
    requires_permissions :manage_server

    def execute
      event.respond(content: "🦈 pong", ephemeral: true)
    end
  end
end
