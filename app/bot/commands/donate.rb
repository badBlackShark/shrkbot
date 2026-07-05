# frozen_string_literal: true

module Commands
  class Donate < BaseCommand
    command_name :donate
    description "Find out what it costs to run shrkbot and how you can support the project."
    register_in :global

    MESSAGE = <<~DONATE
      Thank you for considering supporting the shrkbot project! For full transparency, here's what it currently costs to keep shrkbot running:
      • Hosting: 10.60€ / month

      That's the entire monthly cost as things stand. I'd love to keep growing the project - adding features and improving the ones that are there - and any support makes that easier.

      To be clear: shrkbot is and always will be completely free and open source. You are never obligated to donate - just using shrkbot is more than enough :) And please only ever give money you don't otherwise need.

      Thank you for using shrkbot! If you'd like to chip in:
      • PayPal: https://paypal.me/trueblackshark
      • Liberapay: https://liberapay.com/badBlackShark

      All donations are non-refundable. Thanks for the support! <3
    DONATE

    def execute
      event.respond(content: MESSAGE, ephemeral: true)
    end
  end
end
