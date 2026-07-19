# frozen_string_literal: true

module Lfg
  class DoneLooking < Bot::BaseEvent
    on :button, custom_id: /\Alfg:done:/
    include Lfg::MessageFetching

    def handle
      return unauthorized unless authorized?

      event.defer(ephemeral: true)
      close
      event.edit_response(content: "LFG closed.")
    end

    private

    def authorized?
      CustomId.parse(event.custom_id)[:creator_id] == event.user.id || can_manage?
    end

    def can_manage?
      member = event.server&.member(event.user.id)
      member&.permission?(:manage_messages, event.channel) || false
    end

    def close
      json = fetch_message
      notify_id = json && PostMessage.parse(json)&.dig(:notify_reply_id)
      delete_message(notify_id) if notify_id
      delete_message(event.message.id)
    end

    def unauthorized
      event.respond(content: "Only the poster or a mod can close this LFG.", ephemeral: true)
    end
  end
end
