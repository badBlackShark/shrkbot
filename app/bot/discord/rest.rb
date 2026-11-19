# frozen_string_literal: true

module Bot
  module Discord
    module Rest
      BASE = "https://discord.com/api/#{Config::API_VERSION}"
      READ_TIMEOUT = 5
      STATUS_ERRORS = {401 => Unauthorized, 403 => Unauthorized}.freeze

      module_function

      def get_json(path, authorization:, &)
        ::Integrations::Http.get_json(
          "#{BASE}#{path}",
          headers: {"Authorization" => authorization, "User-Agent" => user_agent},
          status_errors: STATUS_ERRORS,
          read_timeout: READ_TIMEOUT,
          &
        )
      rescue Error
        raise
      rescue ::Integrations::RateLimited => e
        raise RateLimited, e.message
      rescue ::Integrations::Error => e
        raise Error, e.message
      end

      def user_agent
        "DiscordBot (#{ReleaseInfo::REPO_URL}, #{ReleaseInfo.current&.number || "0"})"
      end
      private_class_method :user_agent
    end
  end
end
