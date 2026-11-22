# frozen_string_literal: true

module Feeds
  module ValidatesJsonList
    extend ActiveSupport::Concern

    class_methods do
      def validates_json_list(attribute, max:, &valid_item)
        validate do
          list = public_send(attribute)
          errors.add(attribute, :invalid) unless list.is_a?(Array) && list.all?(&valid_item)
          errors.add(attribute, :too_long, count: max) if list.is_a?(Array) && list.size > max
        end
      end
    end
  end
end
