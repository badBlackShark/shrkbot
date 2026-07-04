# frozen_string_literal: true

module Components
  module Roles
    RoleSetCardData = Data.define(
      :index,
      :set_id,
      :name,
      :selection_mode,
      :channel_override,
      :selected_role_ids,
      :open,
      :repost_path
    ) do
      def self.empty
        new(
          index: "NEW_RECORD",
          set_id: nil,
          name: "",
          selection_mode: "single",
          channel_override: nil,
          selected_role_ids: [],
          open: true,
          repost_path: nil
        )
      end
    end
  end
end
