# frozen_string_literal: true

module Discord
  module CdnUrl
    module_function

    def guild_icon(guild_id, icon_hash)
      "https://cdn.discordapp.com/icons/#{guild_id}/#{icon_hash}.png?size=64" if icon_hash
    end
  end
end
