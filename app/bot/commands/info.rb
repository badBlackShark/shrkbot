# frozen_string_literal: true

module Bot
  module Commands
    class Info < BaseCommand
      command_name :info
      description "Show information about shrkbot - its code, stack, and how to add it to your server."
      register_in :global

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
          Discord::Components.text("**Configure me**\n[Manage this server's settings](#{Config.server_config_url(event.server_id)})")
        ]
      end

      def configurable?
        return false unless event.server_id

        CommandPermissions.owner?(event) || event.user.permission?(:manage_server)
      end

      def header
        "### #{event.bot.profile.username}\n" \
          "I was written in [Ruby](https://www.ruby-lang.org/) by [badBlackShark](https://github.com/badBlackShark/).\n" \
          "My code lives [here](#{ReleaseInfo::REPO_URL}). Want me on your server? [Invite me!](#{Config.invite_url})"
      end

      def credits
        [
          "**[discordrb](https://github.com/shardlab/discordrb)** *by shardlab*",
          "**[Ruby on Rails](https://rubyonrails.org/)** *by the Rails team*"
        ].join("\n")
      end
    end
  end
end
