# frozen_string_literal: true

module Integrations
  module Twitch
    class Users
      def initialize(client: Client.new)
        @client = client
      end

      def find_by_login(login)
        @client.get_json("/users", params: {login:}, status_errors: {400 => InvalidReference}) do |body|
          data = body.fetch("data").first
          raise NotFound, "Twitch has no channel #{login}" unless data

          user(data)
        end
      end

      def for(user_ids)
        user_ids.each_slice(Client::MAX_IDS).flat_map do |ids|
          @client.get_json("/users", params: {id: ids}) do |body|
            body.fetch("data").map { |data| user(data) }
          end
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
