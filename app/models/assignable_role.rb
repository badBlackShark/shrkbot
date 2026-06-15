class AssignableRole < ApplicationRecord
  include PrefixedId

  id_prefix "asr"

  belongs_to :role_setting

  validates :role_id, uniqueness: {scope: :role_setting_id}
end
