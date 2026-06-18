class Plugin < ApplicationRecord
  has_many :plugin_activations, dependent: :delete_all

  validates :key, presence: true, uniqueness: true
  validates :name, presence: true

  scope :enabled, -> { where(plugin_activations: {enabled: true}) }

  def key
    self[:key]&.to_sym
  end
end
