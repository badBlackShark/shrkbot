class Plugin < ApplicationRecord
  has_many :plugin_activations, dependent: :delete_all

  validates :key, presence: true, uniqueness: true
  validates :name, presence: true

  # The catalog key is a stable identifier we branch on in code; expose it as a
  # symbol (stored as text) so call sites read `:welcomes`, not "welcomes".
  # Queries (where/find_by) still accept either — AR casts the symbol to text.
  def key
    self[:key]&.to_sym
  end
end
