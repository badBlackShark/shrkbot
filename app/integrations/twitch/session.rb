# frozen_string_literal: true

module Integrations
  module Twitch
    class Session
      GRACE = 5.minutes
      Outcome = Data.define(:state, :events, :went_offline)

      def initialize(state, now:)
        @state = state
        @now = now
      end

      def apply(observation)
        case observation
        in Live
          live(observation)
        in Offline
          offline
        in Close
          close(observation)
        end
      end

      private

      def live(observation)
        return start(observation) unless open?
        return restart(observation) if grace_elapsed?

        continue(observation)
      end

      def offline
        return unchanged unless open?
        return mark_offline unless @state.key?("offline_at")
        return finish if grace_elapsed?

        unchanged
      end

      def close(observation)
        return unchanged unless open? && @state["offline_at"] == observation.offline_since

        finish
      end

      def open?
        @state.key?("session")
      end

      def grace_elapsed?
        @state.key?("offline_at") && @now - offline_at >= GRACE
      end

      def offline_at
        Time.zone.parse(@state.fetch("offline_at"))
      end

      def unchanged
        outcome(@state)
      end

      def mark_offline
        outcome(@state.merge("offline_at" => @now.iso8601), went_offline: true)
      end

      def start(observation)
        state = {
          "session" => observation.stream_id,
          "stream_ids" => [observation.stream_id],
          "title" => observation.title,
          "category_id" => observation.category_id,
          "category_name" => observation.category_name,
          "started_at" => observation.started_at.iso8601,
          "login" => observation.login,
          "display_name" => observation.display_name,
          "peak_viewers" => observation.viewer_count
        }
        outcome(state, [event(StreamStarted, state, occurred_at: observation.started_at, subject_key: "stream:#{state["session"]}")])
      end

      def restart(observation)
        ended = finish
        started = start(observation)
        outcome(started.state, ended.events + started.events)
      end

      def continue(observation)
        state = @state.except("offline_at").merge(
          "stream_ids" => @state.fetch("stream_ids") | [observation.stream_id],
          "peak_viewers" => [@state.fetch("peak_viewers"), observation.viewer_count].max,
          "login" => observation.login,
          "display_name" => observation.display_name
        )
        return outcome(state) unless changed?(observation)

        state = state.merge(
          "title" => observation.title,
          "category_id" => observation.category_id,
          "category_name" => observation.category_name
        )
        update = event(StreamUpdated, state, occurred_at: @now, subject_key: "stream-update:#{state["session"]}:#{@now.to_i}")
        outcome(state, [update])
      end

      def changed?(observation)
        @state["title"] != observation.title || @state["category_id"] != observation.category_id
      end

      def finish
        ended_at = offline_at
        ended = event(
          StreamEnded,
          @state,
          occurred_at: ended_at,
          subject_key: "stream-end:#{@state["session"]}",
          ended_at: ended_at.iso8601,
          duration: (ended_at - Time.zone.parse(@state.fetch("started_at"))).to_i,
          peak_viewers: @state.fetch("peak_viewers")
        )
        outcome(@state.slice("login", "display_name"), [ended])
      end

      def outcome(state, events = [], went_offline: false)
        Outcome.new(state:, events:, went_offline:)
      end

      def event(klass, state, occurred_at:, subject_key:, **extra)
        klass.new(
          subject_key:,
          occurred_at:,
          session: state["session"],
          login: state["login"],
          display_name: state["display_name"],
          title: state["title"],
          category_id: state["category_id"],
          category_name: state["category_name"],
          started_at: state["started_at"],
          story_key: "stream:#{state["session"]}",
          **extra
        )
      end
    end
  end
end
