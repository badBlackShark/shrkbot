class RoleSetting < ApplicationRecord
  belongs_to :server_configuration
  has_many :assignable_roles, -> { order(:position) }, dependent: :destroy
end
