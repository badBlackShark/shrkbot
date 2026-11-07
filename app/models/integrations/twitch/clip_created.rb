# frozen_string_literal: true

module Integrations
  module Twitch
    class ClipCreated < ClipEvent
      self.secondary = true
    end
  end
end
