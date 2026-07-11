# frozen_string_literal: true

module Bot
  module WithConnection
    def with_connection(&)
      ActiveRecord::Base.connection_pool.with_connection(&)
    end
  end
end
