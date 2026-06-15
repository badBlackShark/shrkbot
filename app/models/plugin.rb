class Plugin < ApplicationRecord
  has_many :plugin_activations, dependent: :destroy

  validates :key, presence: true, uniqueness: true
  validates :name, presence: true
end
