# frozen_string_literal: true

module Feeds
  module Twitch
    module CategoryValue
      module_function

      def dump(category)
        JSON.generate("id" => category["id"], "name" => category["name"])
      end

      def valid?(category)
        category.is_a?(Hash) && category["id"].is_a?(String) && category["id"].present? && category["name"].is_a?(String)
      end

      def parse(value)
        data = JSON.parse(value)
        return unless data.is_a?(Hash)

        category = {"id" => data["id"], "name" => data["name"]}
        category if valid?(category)
      rescue JSON::ParserError
        nil
      end

      def parse_all(values)
        Array(values).filter_map { |value| parse(value) }.uniq { |category| category["id"] }
      end
    end
  end
end
