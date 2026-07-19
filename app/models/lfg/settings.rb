# frozen_string_literal: true

module Lfg
  class Settings < ApplicationRecord
    self.table_name = "lfg_settings"

    include Lfg::SnowflakeArrayLimit

    belongs_to :server_configuration
    has_many :pingable_roles,
      class_name: "Lfg::PingableRole",
      foreign_key: "lfg_settings_id",
      inverse_of: :lfg_settings,
      dependent: :delete_all

    validates :cooldown_seconds,
      numericality: {only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 86_400}
    validates :post_lifetime_minutes,
      numericality: {only_integer: true, greater_than_or_equal_to: 5, less_than_or_equal_to: 10_080}
    validates :default_min_membership_days,
      numericality: {only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 3_650},
      allow_nil: true
    limits_snowflake_arrays :default_required_role_ids, :default_excluded_role_ids, :allowed_channel_ids
  end
end
