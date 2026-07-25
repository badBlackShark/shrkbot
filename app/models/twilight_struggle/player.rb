# frozen_string_literal: true

module TwilightStruggle
  Player = Data.define(:name, :flag, :discord_id) do
    def initialize(name:, flag: nil, discord_id: nil)
      super
    end

    def self.from_payload(payload)
      payload = payload.symbolize_keys
      new(
        name: payload[:name],
        flag: payload[:flag],
        discord_id: payload[:discord_id]
      )
    end

    def to_s
      name
    end
  end
end
