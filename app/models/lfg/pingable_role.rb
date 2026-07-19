# frozen_string_literal: true

module Lfg
  class PingableRole < ApplicationRecord
    self.table_name = "lfg_pingable_roles"

    include Lfg::SnowflakeArrayLimit

    belongs_to :lfg_settings,
      class_name: "Lfg::Settings",
      inverse_of: :pingable_roles

    validates :role_id, presence: true, uniqueness: {scope: :lfg_settings_id}
    validates :min_membership_days,
      numericality: {only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 3_650},
      allow_nil: true
    validate :allowed_channel_ids_not_explicitly_empty
    limits_snowflake_arrays :required_role_ids, :excluded_role_ids, :allowed_channel_ids

    private

    def allowed_channel_ids_not_explicitly_empty
      return if allowed_channel_ids.nil? || allowed_channel_ids.any?

      errors.add(:allowed_channel_ids, "must name at least one channel or inherit the default")
    end
  end
end
