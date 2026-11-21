# frozen_string_literal: true

module TwilightStruggle
  class CountryFlag
    PATH = Rails.root.join("config/country_flags.yml")
    IMAGE_DIR = Rails.root.join("config/country_flag_images")

    class << self
      def for(country_code)
        return if country_code.blank?

        code = country_code.to_s.downcase
        unicode[code] || custom_mention(code)
      end

      def custom_emoji_names
        custom.values
      end

      def image_path(emoji_name)
        IMAGE_DIR.join("#{emoji_name}.png")
      end

      private

      def custom_mention(code)
        emoji_name = custom[code]
        return if emoji_name.nil?

        Bot::Discord::ApplicationEmoji.mention(emoji_name)
      end

      def unicode
        table["unicode"]
      end

      def custom
        table["custom"]
      end

      def table
        @table ||= YAML.load_file(PATH)
      end
    end
  end
end
