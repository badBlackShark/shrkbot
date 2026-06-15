class LoggingSetting < ApplicationRecord
  include PrefixedId

  id_prefix "lgs"

  belongs_to :server_configuration
end
