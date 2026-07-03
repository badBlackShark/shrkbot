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
        Plugin.find_each do |plugin|
          PluginActivation.find_or_create_by!(server_configuration: config, plugin:) { |a| a.enabled = false }
        end
      end

      def ensure_settings(config)
        config.logging_setting || config.create_logging_setting!
        config.role_setting || config.create_role_setting!
        config.welcome_settings || config.create_welcome_settings!
      end
    end
  end
end
