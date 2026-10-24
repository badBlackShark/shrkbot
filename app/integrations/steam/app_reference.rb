# frozen_string_literal: true

module Integrations
  module Steam
    class AppReference
      def self.parse(input)
        text = input.to_s.strip
        digits = text[/\A\d+\z/] || text[%r{/app/(\d+)}, 1]
        app_id = digits && Integer(digits, 10)
        raise InvalidReference, "#{text.inspect} does not name a Steam app" if app_id.nil? || app_id.zero?

        app_id
      end
    end
  end
end
