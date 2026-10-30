# frozen_string_literal: true

module Integrations
  module Twitch
    class Users
      def initialize(client: Client.new)
        @client = client
      end

      def find_by_login(login)
        @client.get_json("/users", params: {login:}) do |body|
          data = body.fetch("data").first
          raise NotFound, "Twitch has no channel #{login}" unless data

          user(data)
        end
      end

      private

      def user(data)
        User.new(
          id: data.fetch("id"),
          login: data.fetch("login"),
          display_name: data.fetch("display_name"),
          profile_image_url: data.fetch("profile_image_url")
        )
      end
    end
  end
end
