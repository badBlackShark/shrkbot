# discordrb runs each handler on its own thread, so DB work must check out (and
# return) its own AR pool connection.
module WithConnection
  def with_connection(&)
    ActiveRecord::Base.connection_pool.with_connection(&)
  end
end
