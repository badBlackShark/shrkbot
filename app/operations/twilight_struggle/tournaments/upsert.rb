# frozen_string_literal: true

module Ops
  module TwilightStruggle
    module Tournaments
      class Upsert < ApplicationOperation
        receives :external_id, :name
        receives :parent, optional: true
        receives :status, optional: true

        def call
          record = ::TwilightStruggle::Tournament.find_or_initialize_by(external_id:)
          record.name = name
          record.parent = parent
          record.status = status

          if record.save
            ok(record)
          else
            failure(record.errors.full_messages)
          end
        end
      end
    end
  end
end
