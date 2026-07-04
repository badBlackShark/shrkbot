# frozen_string_literal: true

module Discord
  ADMINISTRATOR = 0x8
  MANAGE_GUILD = 0x20

  Guild = Data.define(:id, :name, :owner, :permissions, :icon, :member_count) do
    def self.from_api(payload)
      new(
        id: payload["id"].to_i,
        name: payload["name"],
        owner: payload["owner"] == true,
        permissions: payload["permissions"].to_i,
        icon: payload["icon"],
        member_count: payload["approximate_member_count"]
      )
    end

    def initialize(member_count: nil, **rest)
      super
    end

    def manageable?
      owner || permissions.anybits?(ADMINISTRATOR | MANAGE_GUILD)
    end

    def icon_url
      CdnUrl.guild_icon(id, icon)
    end
  end
end
