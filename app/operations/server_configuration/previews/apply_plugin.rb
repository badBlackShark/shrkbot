# frozen_string_literal: true

module Ops
  module ServerConfiguration
    module Previews
      class ApplyPlugin < ApplicationOperation
        receives :server_configuration, :entry

        def call
          settings.update!(**entry[:settings])
          build_records(settings, entry[:records] || {})
          activation.update!(enabled: entry[:enabled])
          ok(settings)
        end

        private

        def settings
          @settings ||= server_configuration.public_send(entry[:settings_association])
        end

        def activation
          server_configuration.plugin_activations.find do |candidate|
            candidate.plugin.key == entry[:plugin].to_sym
          end || raise(ActiveRecord::RecordNotFound, "no plugin activation for key #{entry[:plugin]}")
        end

        def build_records(record, records)
          records.each do |association, entries|
            record.public_send(association).destroy_all
            entries.each { |attributes| build_record(record, association, attributes) }
          end
        end

        def build_record(record, association, attributes)
          scalar_attributes, nested_records = split_nested(attributes)
          child = record.public_send(association).create!(scalar_attributes)
          build_records(child, nested_records)
        end

        def split_nested(attributes)
          scalar, nested = attributes.partition { |_key, value| !nested_association?(value) }
          [scalar.to_h, nested.to_h]
        end

        def nested_association?(value)
          value.is_a?(Array) && value.any? && value.all? { |item| item.is_a?(Hash) }
        end
      end
    end
  end
end
