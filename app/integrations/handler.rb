# frozen_string_literal: true

module Integrations
  module Handler
    extend ActiveSupport::Concern

    class_methods do
      def handles(*event_classes)
        Bus.subscribe(self, to: event_classes)
      end
    end
  end
end
