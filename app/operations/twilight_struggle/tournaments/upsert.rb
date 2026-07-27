# frozen_string_literal: true

module Ops
  module TwilightStruggle
    module Tournaments
      class Upsert < ApplicationOperation
        receives :external_id, :name
        receives :parent, optional: true
        receives :status, optional: true
        receives :admins, optional: true

        def call
          record = ::TwilightStruggle::Tournament.find_or_initialize_by(external_id:)
          record.name = name
          record.parent = parent
          record.status = status

          if record.save
            replace_admins(record) unless admins.nil?
            ok(record)
          else
            failure(record.errors.full_messages)
          end
        end

        private

        def replace_admins(record)
          discord_ids = admins.map(&:to_i).uniq
          record.admins.where.not(discord_id: discord_ids).delete_all
          (discord_ids - record.admins.pluck(:discord_id)).each do |discord_id|
            record.admins.create!(discord_id:)
          end
        end
      end
    end
  end
end
