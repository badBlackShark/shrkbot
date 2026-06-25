# frozen_string_literal: true

module Commands
  class Info < BaseCommand
    command_name :info
    description "Show information about shrkbot — its code, stack, and how to add it to your server."
    register_in :global

    INVITE_URL = "https://discord.com/oauth2/authorize?client_id=346043915142561793"

    def execute
      event.respond(components: message[:components], ephemeral: true, has_components: true)
    end

    private

    def message
      Discord::Components.container(
        [
          Discord::Components.text(header),
          Discord::Components.separator,
          Discord::Components.text("**Built with**\n#{credits}"),
          Discord::Components.separator,
          Discord::Components.text("-# Want to support the project? Use /donate.")
        ]
      )
    end

    def header
      "### #{event.bot.profile.username}\n" \
        "I was written in [Ruby](https://www.ruby-lang.org/) by [badBlackShark](https://github.com/badBlackShark/).\n" \
        "My code lives [here](https://github.com/badBlackShark/shrkbot). Want me on your server? [Invite me!](#{INVITE_URL})"
    end

    def credits
      [
        "**[discordrb](https://github.com/shardlab/discordrb)** *by shardlab*",
        "**[Ruby on Rails](https://rubyonrails.org/)** *by the Rails team*",
        "**[Solid Queue](https://github.com/rails/solid_queue)** *by the Rails team*",
        "**[pg](https://github.com/ged/ruby-pg)** *by Michael Granger et al.*",
        "**[redis-rb](https://github.com/redis/redis-rb)** *by the redis-rb team*"
      ].join("\n")
    end
  end
end
