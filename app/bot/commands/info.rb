# frozen_string_literal: true

module Commands
  class Info < BaseCommand
    command_name :info
    description "Show information about shrkbot - its code, stack, and how to add it to your server."
    register_in :global

    INVITE_URL = "https://discord.com/oauth2/authorize?client_id=346043915142561793"
    MASCOT_PATH = Rails.root.join("app/assets/images/shrkbot-mascot.png")

    def execute
      event.respond(
        components: message[:components],
        attachments: [MASCOT_PATH.open],
        ephemeral: true,
        has_components: true
      )
    end

    private

    def message
      Discord::Components.container(
        [
          Discord::Components.section(
            [Discord::Components.text(header)],
            accessory: Discord::Components.thumbnail("attachment://#{MASCOT_PATH.basename}")
          ),
          Discord::Components.separator,
          Discord::Components.text("**Built with**\n#{credits}"),
          *configuration_section,
          Discord::Components.separator,
          Discord::Components.text("-# Want to support the project? Use /donate.")
        ]
      )
    end

    def configuration_section
      return [] unless configurable?

      [
        Discord::Components.separator,
        Discord::Components.text("**Configure me**\n[Manage this server's settings](#{BotConfig.server_config_url(event.server_id)})")
      ]
    end

    def configurable?
      return false unless event.server_id

      CommandPermissions.permitted?(
        event:,
        required: [:manage_server],
        owner_only: false
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
        "**[Ruby on Rails](https://rubyonrails.org/)** *by the Rails team*"
      ].join("\n")
    end
  end
end
