class ServerConfiguration < ApplicationRecord
  has_many :plugin_activations, dependent: :delete_all
  has_many :plugins, through: :plugin_activations
  has_many :enabled_plugins, -> { where(plugin_activations: {enabled: true}) },
    through: :plugin_activations, source: :plugin

  has_one :logging_setting, dependent: :delete
  has_one :role_setting, dependent: :destroy # RoleSetting cascades to its assignable_roles
  has_one :welcome_settings, class_name: "Welcomes::Settings", dependent: :delete

  validates :discord_id, presence: true, uniqueness: true
end
