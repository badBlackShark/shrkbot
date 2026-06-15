class AssignableRole < ApplicationRecord
  belongs_to :role_setting

  validates :role_id, uniqueness: { scope: :role_setting_id }
end
