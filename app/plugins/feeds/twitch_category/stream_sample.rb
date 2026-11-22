# frozen_string_literal: true

module Feeds
  class TwitchCategory
    module StreamSample
      def self.call(category_id)
        Integrations::Twitch::CategoryStreams.new.current(category_id).map do |stream|
          {viewers: stream.viewer_count, language: stream.language, login: stream.user_login.downcase}
        end
      rescue Integrations::Error
        nil
      end
    end
  end
end
