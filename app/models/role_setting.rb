class RoleSetting < ApplicationRecord
  include PrefixedId

  id_prefix "rls"

  belongs_to :server_configuration
  has_many :assignable_roles, -> { order(:position) }, dependent: :destroy
end
