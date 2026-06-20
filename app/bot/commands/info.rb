module Commands
  class Info < BaseCommand
    command_name :info
    description "Show information about shrkbot — its code, stack, and how to add it to your server."
    register_in :global

    INVITE_URL = "https://discord.com/oauth2/authorize?client_id=346043915142561793"
    ACCENT_COLOR = 0x39afe5

    def execute
      event.respond(embeds: [embed(event.bot.profile)])
    end

    private

    def embed(profile)
      {
        author: {name: profile.username, icon_url: profile.avatar_url},
        description: "I was written in [Ruby](https://www.ruby-lang.org/) by [badBlackShark](https://github.com/badBlackShark/).\n" \
          "My code lives [here](https://github.com/badBlackShark/shrkbot). Want me on your server? [Invite me!](#{INVITE_URL})",
        fields: [{name: "Built with", value: credits}],
        color: ACCENT_COLOR,
        footer: {text: "Want to support the project? Use /donate."}
      }
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
