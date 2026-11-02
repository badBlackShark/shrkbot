# frozen_string_literal: true

module Integrations
  module Twitch
    class Session
      GRACE = 5.minutes
      STALE_AFTER = 20.minutes
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
        in ChannelUpdate
          channel_update(observation)
        end
      end

      private

      def live(observation)
        return start(observation) unless open?
        return restart(observation) if stale? && !@state.fetch("stream_ids").include?(observation.stream_id)

        continue(observation)
      end

      def offline
        return outcome(@state) unless open?
        return finish(last_live_at) if stale?
        return outcome(@state) if @state.key?("offline_at")

        outcome(@state.merge("offline_at" => @now.iso8601), went_offline: true)
      end

      def close(observation)
        return outcome(@state) unless open? && @state["offline_at"] == observation.offline_since

        finish(Time.zone.parse(observation.offline_since))
      end

      def open?
        @state.key?("session")
      end

      def stale?
        @now - last_live_at > STALE_AFTER
      end

      def last_live_at
        Time.zone.parse(@state.fetch("last_live_at"))
      end

      def start(observation)
        state = {
          "session" => observation.stream_id,
          "stream_ids" => [observation.stream_id],
          "title" => observation.title,
          "category_id" => observation.category_id,
          "category_name" => observation.category_name,
          "started_at" => observation.started_at.iso8601,
          "last_live_at" => @now.iso8601,
          "login" => observation.login,
          "display_name" => observation.display_name,
          "peak_viewers" => observation.viewer_count
        }
        outcome(state, [event(StreamStarted, state, occurred_at: observation.started_at, subject_key: "stream:#{state["session"]}")])
      end

      def restart(observation)
        ended = finish(last_live_at)
        started = start(observation)
        outcome(started.state, ended.events + started.events)
      end

      def continue(observation)
        state = @state.except("offline_at").merge(
          "stream_ids" => @state.fetch("stream_ids") | [observation.stream_id],
          "last_live_at" => @now.iso8601,
          "peak_viewers" => [@state.fetch("peak_viewers"), observation.viewer_count].max,
          "login" => observation.login,
          "display_name" => observation.display_name
        )
        update(state, observation)
      end

      def channel_update(observation)
        return outcome(@state) unless open?

        update(@state, observation)
      end

      def update(state, observation)
        return outcome(state) unless changed?(observation)

        state = state.merge(
          "title" => observation.title,
          "category_id" => observation.category_id,
          "category_name" => observation.category_name
        )
        outcome(state, [event(StreamUpdated, state, occurred_at: @now, subject_key: "stream-update:#{state["session"]}:#{@now.to_i}")])
      end

      def changed?(observation)
        @state["title"] != observation.title || @state["category_id"] != observation.category_id
      end

      def finish(ended_at)
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
