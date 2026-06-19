module Ops
  module ServerConfiguration
    class Ensure < ApplicationOperation
      self.transactional = false

      receives :discord_id

      def execute
        config = transaction do
          sc = ::ServerConfiguration.find_or_create_by!(discord_id: discord_id)
          ensure_activations(sc)
          sc
        end
        ok(config)
      rescue ActiveRecord::RecordNotUnique
        ok(::ServerConfiguration.find_by!(discord_id: discord_id))
      end

      private

      def ensure_activations(config)
        Plugin.find_each do |plugin|
          PluginActivation.find_or_create_by!(server_configuration: config, plugin:) { |a| a.enabled = false }
        end
      end
    end
  end
end
