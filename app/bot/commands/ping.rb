# Operator liveness check. Admin-gated so it also exercises permission hiding
# (default_member_permissions) + the runtime gate end-to-end.
module Commands
  class Ping < BaseCommand
    command_name :ping
    description "Check that the bot is online and responding."
    requires_permissions :manage_server
    register_in :guild

    def execute
      event.respond(content: "🦈 pong", ephemeral: true)
    end
  end
end
