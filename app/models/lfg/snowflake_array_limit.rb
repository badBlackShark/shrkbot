# frozen_string_literal: true

module Lfg
  module SnowflakeArrayLimit
    extend ActiveSupport::Concern

    MAX_SNOWFLAKES = 50

    class_methods do
      def limits_snowflake_arrays(*attributes)
        validate do
          attributes.each do |attribute|
            values = public_send(attribute)
            next if values.nil? || values.size <= MAX_SNOWFLAKES

            errors.add(attribute, "can have at most #{MAX_SNOWFLAKES} entries")
          end
        end
      end
    end
  end
end
