# frozen_string_literal: true

module Integrations
  module Twitch
    class ChannelReference
      URL = %r{\A(?:https?://)?(?:(?:www|m)\.)?twitch\.tv/([A-Za-z0-9_]+)}i
      LOGIN = /\A@?([A-Za-z0-9_]{1,25})\z/

      def self.url(login)
        "https://www.twitch.tv/#{login}"
      end

      def self.parse(input)
        text = input.to_s.strip
        login = text[URL, 1] || text[LOGIN, 1]
        raise InvalidReference, "#{text.inspect} does not name a Twitch channel" if login.nil? || login.length > 25

        login.downcase
      end
    end
  end
end
