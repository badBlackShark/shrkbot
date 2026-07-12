# frozen_string_literal: true

module Moderation
  module ImageScanning
    CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze
    IMAGE_EXTENSIONS = %w[.png .jpg .jpeg .webp].freeze
    DISCORD_CDN_HOSTS = %w[cdn.discordapp.com media.discordapp.net].freeze
  end
end
