# frozen_string_literal: true

module Components
  module Roles
    RoleFormContext = Data.define(
      :channels,
      :role_options,
      :channels_by_id,
      :default_channel_id,
      :any_unassignable
    )
  end
end
