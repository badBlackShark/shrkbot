# frozen_string_literal: true

module Bot
  module Discord
    module Rest
      BASE = "https://discord.com/api/#{Config::API_VERSION}"
      READ_TIMEOUT = 5

      module_function

      def get_json(path, authorization:, &)
        ::Integrations::Http.get_json(
          "#{BASE}#{path}",
          headers: {"Authorization" => authorization, "User-Agent" => user_agent},
          read_timeout: READ_TIMEOUT,
          &
        )
      end

      def user_agent
        "DiscordBot (#{ReleaseInfo::REPO_URL}, #{ReleaseInfo.current&.number || "0"})"
      end
      private_class_method :user_agent
    end
  end
end
