class ServerConfiguration < ApplicationRecord
  include PrefixedId

  id_prefix "srv"

  has_many :plugin_activations, dependent: :destroy
  has_many :plugins, through: :plugin_activations
  has_many :enabled_plugins, -> { where(plugin_activations: {enabled: true}) },
    through: :plugin_activations, source: :plugin

  has_one :logging_setting, dependent: :destroy
  has_one :role_setting, dependent: :destroy
  has_one :welcome_setting, dependent: :destroy

  validates :discord_id, presence: true, uniqueness: true
end
