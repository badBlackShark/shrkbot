class WelcomeSetting < ApplicationRecord
  include PrefixedId

  id_prefix "wls"

  belongs_to :server_configuration
end
