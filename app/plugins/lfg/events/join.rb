# frozen_string_literal: true

module Lfg
  class Join < Bot::BaseEvent
    include Lfg::MessageFetching

    on :button, custom_id: /\Alfg:join:/

    CAP = 100
    MUTEX = Mutex.new

    def handle
      event.defer_update
      MUTEX.synchronize do
        json = fetch_message
        state = json && PostMessage.parse(json)
        return unless state

        act(CustomId.parse(event.custom_id), state)
      end
    end

    private

    def act(identity, state)
      user_id = event.user.id
      return host_notice if user_id == identity[:creator_id]

      if state[:joiner_ids].include?(user_id)
        rerender(identity, state[:message], state[:joiner_ids] - [user_id])
      else
        join(identity, state, user_id)
      end
    end

    def host_notice
      event.send_message(content: "You're the host, you're always in.", ephemeral: true)
    end

    def join(identity, state, user_id)
      return full if state[:joiner_ids].size >= CAP

      joiners = state[:joiner_ids] + [user_id]
      rerender(identity, state[:message], joiners)
      notify(identity, user_id) if started?(identity)
    end

    def rerender(identity, note, joiners)
      container = PostMessage.render(
        role_id: identity[:role_id],
        creator_id: identity[:creator_id],
        start_ts: identity[:start_ts],
        message: note,
        joiner_ids: joiners,
        started: started?(identity)
      )
      Bot::Discord::Components.convert_to_v2(event.channel.id, event.message.id, container)
    end

    def notify(identity, newest_id)
      record = Lfg::Message.find_by(message_id: event.message.id)
      delete_message(record.notify_reply_id) if record&.notify_reply_id
      announcement = "<@#{identity[:creator_id]}> - <@#{newest_id}> is joining!"
      reply_id = Lfg::PingReply.deliver(
        channel_id: event.channel.id,
        reply_to_id: event.message.id,
        subject: announcement,
        allowed_mentions: {parse: [], users: [identity[:creator_id]]},
        container: Bot::Discord::Components.container([Bot::Discord::Components.text(announcement)])
      )
      Ops::Lfg::Message::Update.call(message: record, notify_reply_id: reply_id) if record
    end

    def full
      event.send_message(content: "This Looking for Game is full (#{CAP} players).", ephemeral: true)
    end

    def started?(identity)
      Time.current.to_i >= identity[:start_ts]
    end
  end
end
