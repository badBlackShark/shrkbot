module WithConnection
  def with_connection(&)
    ActiveRecord::Base.connection_pool.with_connection(&)
  end
end
