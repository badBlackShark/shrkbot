# frozen_string_literal: true

class ServerChannel < ApplicationRecord
  belongs_to :server_configuration
  has_many :channel_overwrites, dependent: :delete_all

  validates :discord_id, presence: true, uniqueness: {scope: :server_configuration_id}
  validates :name, presence: true
  validates :channel_type, presence: true

  VIEW_CHANNEL = 1 << 10

  TEXT_TYPES = [0, 5].freeze

  CATEGORY_TYPE = 4

  scope :text, -> { where(channel_type: TEXT_TYPES).order(:name) }
  scope :in_discord_order, -> {
    joins(<<~SQL)
      LEFT JOIN server_channels categories
        ON categories.server_configuration_id = server_channels.server_configuration_id
        AND categories.discord_id = server_channels.parent_id
    SQL
      .reorder(Arel.sql(
        "categories.position NULLS FIRST, categories.name, server_channels.position, server_channels.name"
      ))
  }

  def everyone_visible?
    overwrite = channel_overwrites.find_by(target_id: server_configuration.discord_id)
    return true unless overwrite

    !overwrite.deny.anybits?(VIEW_CHANNEL)
  end
end
