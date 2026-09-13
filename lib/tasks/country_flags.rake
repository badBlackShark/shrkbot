# frozen_string_literal: true

namespace :twilight_struggle do
  desc "Upload the regional flags Unicode has no emoji for to this bot's Discord application"
  task upload_country_flags: :environment do
    require "discordrb"

    emoji = Bot::Discord::ApplicationEmoji
    emoji.reset!

    TwilightStruggle::CountryFlag.custom_emoji_names.each do |emoji_name|
      if emoji.ids.key?(emoji_name)
        puts "#{emoji_name} is already uploaded"
        next
      end

      emoji.upload(emoji_name, TwilightStruggle::CountryFlag.image_path(emoji_name))
      emoji.reset!
      puts "uploaded #{emoji_name}"
    end
  end
end
