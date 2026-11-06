# frozen_string_literal: true

module Bot
  module Discord
    module Timestamp
      module_function

      def relative(time)
        "<t:#{time.to_i}:R>"
      end
    end
  end
end
