# frozen_string_literal: true

module Integrations
  module Twitch
    class Previews
      URL = "https://static-cdn.jtvnw.net/previews-ttv/live_user_%<login>s-1280x720.jpg"

      def url_for(login)
        url = format(URL, login:)
        # Until a stream's first frame exists, Twitch redirects this URL to its grey 404_preview image.
        Http.head(url, status_errors: {302 => NotFound})
        url
      rescue NotFound
        nil
      end
    end
  end
end
