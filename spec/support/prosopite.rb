# frozen_string_literal: true

require "prosopite"

RSpec.configure do |config|
  config.before(:each) do |example|
    Prosopite.scan unless example.metadata[:skip_prosopite]
  end

  config.after(:each) do |example|
    Prosopite.finish unless example.metadata[:skip_prosopite]
  end
end

Prosopite.raise = true
Prosopite.rails_logger = false

# Rejected finding: the tournament-tree walk queries once per chain level, not once per row.
# Rejected finding: preview seeding activates a handful of interdependent plugins and rebuilds
# a handful of nested record trees once, at seed time — once per plugin/association, not per row.
Prosopite.allow_stack_paths = [
  "app/models/twilight_struggle/administered_tournaments.rb",
  "app/operations/server_configuration/previews/apply_plugin.rb"
]
