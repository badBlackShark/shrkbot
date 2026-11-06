# frozen_string_literal: true

module Integrations
  module Twitch
    class StreamEnded < StreamEvent
      store_accessor :payload, :ended_at, :duration, :peak_viewers, :stream_ids
    end
  end
end
