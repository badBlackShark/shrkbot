# frozen_string_literal: true

module Feeds
  class StoryLock
    def self.hold(server_configuration, story_key)
      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute(
          ActiveRecord::Base.sanitize_sql_array(
            ["SELECT pg_advisory_xact_lock(hashtext(?))", "feeds-story:#{server_configuration.id}:#{story_key}"]
          )
        )
        yield
      end
    end
  end
end
