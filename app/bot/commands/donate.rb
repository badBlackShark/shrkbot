# frozen_string_literal: true

module Bot
  module Commands
    class Donate < BaseCommand
      command_name :donate
      description "Find out what it costs to run shrkbot and how you can support the project."
      register_in :global

      COSTS = <<~COSTS.strip
        ### Support shrkbot
        Thank you for considering supporting the project! For full transparency, here's what it currently costs to keep shrkbot running:
        - Hosting: 10.60€ / month
        - Email hosting: 4.99€ / month
        - Website domain: 17.37€ / year

        That's everything as things stand - roughly 17€ a month all told. I'd love to keep growing the project - adding features and improving the ones that are there - and any support makes that easier.
      COSTS

      PLEDGE = "To be clear: shrkbot is and always will be completely free and open source. " \
        "You are never obligated to donate - just using shrkbot is more than enough :) " \
        "And please only ever give money you don't otherwise need."

      LINKS = "**If you'd like to chip in:**\n" \
        "[PayPal](https://paypal.me/trueblackshark) · [Liberapay](https://liberapay.com/badBlackShark)"

      FOOTER = "-# All donations are non-refundable. Thanks for the support! <3"

      def execute
        event.respond(components: message[:components], ephemeral: true, has_components: true)
      end

      private

      def message
        Discord::Components.container(
          [
            Discord::Components.text(COSTS),
            Discord::Components.separator,
            Discord::Components.text(PLEDGE),
            Discord::Components.separator,
            Discord::Components.text(LINKS),
            Discord::Components.separator,
            Discord::Components.text(FOOTER)
          ]
        )
      end
    end
  end
end
