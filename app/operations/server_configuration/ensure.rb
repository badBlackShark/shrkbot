module Ops
  module ServerConfiguration
    class Ensure < ApplicationOperation
      # Idempotent, add-only: ensures a server has a config + its plugin activation
      # rows. Called on a live join (ServerSetup) and the startup ready-sweep
      # (ServerBackfill). Never deletes, so settings survive a kick + re-invite.
      def initialize(discord_id:)
        @discord_id = discord_id
      end

      def call
        config = transaction do
          sc = ::ServerConfiguration.find_or_create_by!(discord_id: @discord_id)
          ensure_activations(sc)
          sc
        end
        ok(config)
      rescue ActiveRecord::RecordNotUnique
        # A concurrent server_create (shard/reconnect replay) won the insert.
        ok(::ServerConfiguration.find_by!(discord_id: @discord_id))
      end

      private

      # Activations start disabled; an admin enables them via the web UI, which
      # enforces each plugin's prerequisites. (Plugin#default_enabled is a UI
      # pre-selection hint, not applied here.)
      def ensure_activations(config)
        Plugin.find_each do |plugin|
          PluginActivation.find_or_create_by!(server_configuration: config, plugin:) { |a| a.enabled = false }
        end
      end
    end
  end
end
