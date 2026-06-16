module Reminders
  # Defangs @everyone/@here so a delivered reminder can't trigger a mass ping.
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
