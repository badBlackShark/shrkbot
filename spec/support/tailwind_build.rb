# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    system(*Tailwindcss::Commands.compile_command(silent: true), exception: true)
  end
end
