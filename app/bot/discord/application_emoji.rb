# frozen_string_literal: true

module Bot
  module Discord
    class ApplicationEmoji
      class << self
        def mention(emoji_name)
          id = ids[emoji_name.to_s]
          return if id.blank?

          "<:#{emoji_name}:#{id}>"
        rescue => error
          Rails.logger.error { "#{self} could not resolve the emoji #{emoji_name}: #{error.message}" }
          nil
        end

        def upload(emoji_name, image_path)
          request(:applications_aid_emojis, :post, "applications/#{application_id}/emojis",
            {name: emoji_name, image: data_uri(image_path)})
        end

        def ids
          @ids ||= listed_ids
        end

        def reset!
          @ids = nil
          @application_id = nil
        end

        private

        def listed_ids
          listed = request(:applications_aid_emojis, :get, "applications/#{application_id}/emojis")
          listed.fetch("items").to_h { |emoji| [emoji["name"], emoji["id"]] }
        end

        def application_id
          @application_id ||= request(:applications_me, :get, "applications/@me").fetch("id")
        end

        # discordrb wraps no application-emoji endpoint, so these go through its
        # generic request method, which still counts against its rate limiter.
        def request(rate_limit_key, verb, path, body = nil)
          arguments = ["#{Discordrb::API.api_base}/#{path}"]
          arguments << body.to_json if body
          arguments << {Authorization: Bot::Config.rest_token}.merge(body ? {content_type: :json} : {})

          JSON.parse(Discordrb::API.request(rate_limit_key, nil, verb, *arguments))
        end

        def data_uri(image_path)
          "data:image/png;base64,#{[File.binread(image_path)].pack("m0")}"
        end
      end
    end
  end
end
