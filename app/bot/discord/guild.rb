module Discord
  ADMINISTRATOR = 0x8
  MANAGE_GUILD = 0x20

  Guild = Data.define(:id, :name, :owner, :permissions, :icon) do
    def self.from_api(payload)
      new(
        id: payload["id"].to_i,
        name: payload["name"],
        owner: payload["owner"] == true,
        permissions: payload["permissions"].to_i,
        icon: payload["icon"]
      )
    end

    def manageable?
      owner || permissions.anybits?(ADMINISTRATOR | MANAGE_GUILD)
    end

    def icon_url
      "https://cdn.discordapp.com/icons/#{id}/#{icon}.png?size=64" if icon
    end
  end
end
