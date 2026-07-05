# frozen_string_literal: true

module Ops
  module ServerConfiguration
    class Destroy < ApplicationOperation
      receives :server_configuration

      def call
        purge_reminders
        server_configuration.destroy!
        ok(server_configuration)
      end

      private

      def purge_reminders
        reminders = ::Reminders::Reminder.where(server_id: server_configuration.discord_id)
        channel_bound = reminders.where(deliver_via_dm: false)
        if server_configuration.force_dm_reminders
          channel_bound.update_all(deliver_via_dm: true)
        else
          channel_bound.delete_all
        end
        reminders.update_all(server_id: nil)
      end
    end
  end
end
