# frozen_string_literal: true

module Ops
  module TwilightStruggle
    module Games
      class Upsert < ApplicationOperation
        receives :external_id, :payload
        receives :tournament, optional: true

        def call
          record = ::TwilightStruggle::Game.find_or_initialize_by(external_id:)
          record.tournament = tournament || friendly_tournament

          return failure(record.errors.full_messages) unless record.save

          enqueue_post(record)
          ok(record)
        end

        private

        def enqueue_post(record)
          servers = record.tournament.subscribed_servers.to_a

          return log_no_subscribers(record) if servers.empty?

          servers.each { |server| ::TwilightStruggle::PostJob.perform_later(record, server, payload) }
        end

        def log_no_subscribers(record)
          Rails.logger.info { "#{self.class} did not post game #{record.external_id}: no server subscribes to #{record.tournament.name}." }
        end

        def friendly_tournament
          ::TwilightStruggle::Tournament.find_by(friendly: true) || create_friendly_tournament
        end

        def create_friendly_tournament
          ::TwilightStruggle::Tournament.create!(friendly: true, name: I18n.t("twilight_struggle.friendly_tournament_name"))
        rescue ActiveRecord::RecordNotUnique
          ::TwilightStruggle::Tournament.find_by!(friendly: true)
        end
      end
    end
  end
end
