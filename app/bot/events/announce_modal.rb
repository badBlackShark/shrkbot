# frozen_string_literal: true

module Bot
  class AnnounceModal < BaseEvent
    on :modal_submit, custom_id: Commands::Announce::MODAL_ID

    def handle
      return reject unless owner?

      event.defer(ephemeral: true)
      result = OwnerBroadcast.call(bots: Registry.all, content:)
      event.edit_response(
        content: "Sent to #{result.sent}/#{result.owner_count} unique owner(s) across #{result.server_count} server(s)."
      )
    end

    private

    def content
      event.value(Commands::Announce::INPUT_ID).to_s
    end

    def owner?
      CommandPermissions.permitted?(event:, owner_only: true)
    end

    def reject
      event.respond(content: "🚫 You don't have permission to do that.", ephemeral: true)
    end
  end
end
