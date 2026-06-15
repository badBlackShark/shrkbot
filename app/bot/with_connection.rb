# Shared by commands and event handlers: discordrb dispatches every handler on
# its own thread, so each must check a connection out of the AR pool and return
# it. Wrap all DB-touching handler work in this.
module WithConnection
  def with_connection(&)
    ActiveRecord::Base.connection_pool.with_connection(&)
  end
end
