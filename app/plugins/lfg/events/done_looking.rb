# frozen_string_literal: true

module Lfg
  class DoneLooking < Bot::BaseEvent
    include Lfg::MessageFetching

    on :button, custom_id: /\Alfg:done:/

    def handle
      return unauthorized unless authorized?

      event.defer(ephemeral: true)
      close
      event.edit_response(content: "Looking for Game closed.")
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
      record = Lfg::Message.find_by(message_id: event.message.id)
      if record
        record.follow_up_ids.each { |id| delete_message(id) }
        Ops::Lfg::Message::Destroy.call(message: record)
      end
      delete_message(event.message.id)
    end

    def unauthorized
      event.respond(content: "Only the poster or a mod can close this Looking for Game.", ephemeral: true)
    end
  end
end
