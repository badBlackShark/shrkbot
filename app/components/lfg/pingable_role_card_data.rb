# frozen_string_literal: true

module Components
  module Lfg
    PingableRoleCardData = Data.define(
      :index,
      :role_id,
      :required_role_ids,
      :excluded_role_ids,
      :allowed_channel_ids,
      :min_membership_days,
      :open
    ) do
      def self.empty
        new(
          index: "NEW_RECORD",
          role_id: nil,
          required_role_ids: [],
          excluded_role_ids: [],
          allowed_channel_ids: [],
          min_membership_days: nil,
          open: true
        )
      end
    end
  end
end
