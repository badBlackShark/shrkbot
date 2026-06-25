# frozen_string_literal: true

module Reminders
  module Sanitizer
    ZERO_WIDTH = "​"

    module_function

    def call(text)
      text.to_s
        .gsub("@everyone", "@#{ZERO_WIDTH}everyone")
        .gsub("@here", "@#{ZERO_WIDTH}here")
    end
  end
end
