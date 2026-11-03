# frozen_string_literal: true

module Integrations
  module Twitch
    class StreamStarted < StreamEvent
      def expired?
        watch.state["session"] != session
      end
    end
  end
end
