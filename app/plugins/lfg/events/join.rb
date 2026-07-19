# frozen_string_literal: true

module Lfg
  class Join < Bot::BaseEvent
    on :button, custom_id: /\Alfg:join:/
    include Lfg::MessageFetching

    CAP = 100
    MUTEX = Mutex.new

    def handle
      event.defer_update
      MUTEX.synchronize do
        json = fetch_message
        state = json && PostMessage.parse(json)
        return unless state

        toggle(state)
      end
    end

    private

    def toggle(state)
      user_id = event.user.id
      if state[:joiner_ids].include?(user_id)
        leave(state, user_id)
      else
        join(state, user_id)
      end
    end

    def join(state, user_id)
      return full if state[:joiner_ids].size >= CAP

      joiners = state[:joiner_ids] + [user_id]
      notify_id = notify(state, user_id, joiners.size)
      rerender(state, joiners, notify_id)
    end

    def leave(state, user_id)
      rerender(state, state[:joiner_ids] - [user_id], state[:notify_reply_id])
    end

    def notify(state, user_id, count)
      return state[:notify_reply_id] unless started?(state)

      delete_message(state[:notify_reply_id]) if state[:notify_reply_id]
      Lfg::PingReply.deliver(
        channel_id: event.channel.id,
        reply_to_id: event.message.id,
        subject: "<@#{state[:creator_id]}> — <@#{user_id}> is in (#{count} waiting).",
        allowed_mentions: {parse: [], users: [state[:creator_id]]},
        container: Bot::Discord::Components.container([Bot::Discord::Components.text("<@#{state[:creator_id]}> — <@#{user_id}> is in (#{count} waiting).")])
      )
    end

    def rerender(state, joiners, notify_id)
      container = PostMessage.render(
        role_id: state[:role_id],
        creator_id: state[:creator_id],
        start_ts: state[:start_ts],
        message: state[:message],
        joiner_ids: joiners,
        notify_reply_id: notify_id,
        started: started?(state)
      )
      Bot::Discord::Components.convert_to_v2(event.channel.id, event.message.id, container)
    end

    def full
      event.send_message(content: "This LFG is full (#{CAP} players).", ephemeral: true)
    end

    def started?(state)
      Time.current.to_i >= state[:start_ts]
    end
  end
end
