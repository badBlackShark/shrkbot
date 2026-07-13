# frozen_string_literal: true

module Moderation
  module ImageScanning
    CONTENT_TYPES = %w[image/png image/jpeg image/webp image/gif].freeze
    IMAGE_EXTENSIONS = %w[.png .jpg .jpeg .webp .gif].freeze
    DISCORD_CDN_HOSTS = %w[cdn.discordapp.com media.discordapp.net].freeze
    CONFIRMED_HASH_STATES = %i[own_confirmed global_confirmed].freeze
  end
end
