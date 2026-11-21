# frozen_string_literal: true

module LfgMember
  def lfg_member(id: 1, role_ids: [], joined_at: Time.current)
    require "discordrb"

    instance_double(
      Discordrb::Member,
      id:,
      roles: role_ids.map { |role_id| instance_double(Discordrb::Role, id: role_id) },
      joined_at:
    )
  end

  def lfg_channel(id: 20)
    require "discordrb"

    instance_double(Discordrb::Channel, id:)
  end
end

RSpec.configure do |config|
  config.include LfgMember
end
