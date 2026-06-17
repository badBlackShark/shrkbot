class AssignableRole < ApplicationRecord
  belongs_to :role_setting

  validates :role_id, presence: true, uniqueness: {scope: :role_setting_id}
end
