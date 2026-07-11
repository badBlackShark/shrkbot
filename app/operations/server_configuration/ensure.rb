# frozen_string_literal: true

module Ops
  module ServerConfiguration
    class Ensure < ApplicationOperation
      self.transactional = false

      receives :discord_id

      def call
        config = transaction do
          sc = ::ServerConfiguration.find_or_create_by!(discord_id:)
          ensure_activations(sc)
          ensure_settings(sc)
          sc
        end
        ok(config)
      rescue ActiveRecord::RecordNotUnique
        ok(::ServerConfiguration.find_by!(discord_id:))
      end

      private

      def ensure_activations(config)
        existing_plugin_ids = config.plugin_activations.pluck(:plugin_id)
        Plugin.where.not(id: existing_plugin_ids).find_each do |plugin|
          PluginActivation.create!(server_configuration: config, plugin:, enabled: false)
        end
      end

      def ensure_settings(config)
        config.logging_setting || config.create_logging_setting!
        config.role_setting || config.create_role_setting!
        config.welcome_settings || config.create_welcome_settings!
        config.moderation_settings || config.create_moderation_settings!
        config.spam_protection_settings || config.create_spam_protection_settings!
        config.image_scanning_settings || config.create_image_scanning_settings!
      end
    end
  end
end
