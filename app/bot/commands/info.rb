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
            Discord::Components.separator,
            Discord::Components.text("-# Want to support the project? Use /donate.")
          ],
          buttons:
        )
      end

      def buttons
        base = [
          Discord::Components.link_button(url: ReleaseInfo::REPO_URL, label: "GitHub"),
          Discord::Components.link_button(url: Config.invite_url, label: "Invite me")
        ]
        return base unless configurable?

        base << Discord::Components.link_button(
          url: Config.server_config_url(event.server_id),
          label: "Server settings"
        )
      end

      def configurable?
        return false unless event.server_id

        CommandPermissions.owner?(event) || event.user.permission?(:manage_server)
      end

      def header
        "### #{event.bot.profile.username}\n" \
          "I was written in [Ruby](https://www.ruby-lang.org/) by [badBlackShark](https://github.com/badBlackShark/)."
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
