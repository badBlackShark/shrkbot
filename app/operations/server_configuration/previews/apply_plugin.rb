# frozen_string_literal: true

module Ops
  module ServerConfiguration
    module Previews
      class ApplyPlugin < ApplicationOperation
        receives :server_configuration, :entry

        def call
          owner.update!(**entry[:settings]) if entry[:settings]
          build_records(owner, entry[:records] || {})
          activation.update!(enabled: entry[:enabled])
          ok(owner)
        end

        private

        def owner
          @owner ||= server_configuration.public_send(entry.fetch(:settings_association, :itself))
        end

        def activation
          server_configuration.plugin_activations.find do |candidate|
            candidate.plugin.key == entry[:plugin].to_sym
          end || raise(ActiveRecord::RecordNotFound, "no plugin activation for key #{entry[:plugin]}")
        end

        def build_records(record, records)
          records.each do |association, entries|
            record.public_send(association).destroy_all if collection?(record, association)
            entries.each { |attributes| build_record(record, association, attributes) }
          end
        end

        def build_record(record, association, attributes)
          scalars, references, nested_records = split_attributes(attributes)
          child_class = record.class.reflect_on_association(association).klass
          child = create_child(record, association, scalars.merge(resolve_references(child_class, references)))
          build_records(child, nested_records)
        end

        def create_child(record, association, attributes)
          if collection?(record, association)
            record.public_send(association).create!(attributes)
          else
            record.public_send(:"create_#{association}!", attributes)
          end
        end

        def collection?(record, association)
          record.class.reflect_on_association(association).collection?
        end

        def split_attributes(attributes)
          nested, rest = attributes.partition { |_key, value| nested_association?(value) }
          references, scalars = rest.partition { |_key, value| reference?(value) }
          [scalars.to_h, references.to_h, nested.to_h]
        end

        def resolve_references(child_class, references)
          references.to_h do |attribute, reference|
            target = child_class.reflect_on_association(attribute).klass
            [attribute, target.create_with(reference.fetch(:create_with, {})).find_or_create_by!(reference.fetch(:find_by))]
          end
        end

        def nested_association?(value)
          value.is_a?(Array) && value.any? && value.all? { |item| item.is_a?(Hash) }
        end

        def reference?(value)
          value.is_a?(Hash) && value.key?(:find_by)
        end
      end
    end
  end
end
