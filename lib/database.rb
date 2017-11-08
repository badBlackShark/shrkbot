require 'sequel'
require 'mysql2'
require 'net/ssh/gateway'

# Allows access to a MySQL database via a few, predefined methods.
class Database
  attr_reader :database
  attr_reader :gateway

  # Connects to the database using the given information, using an SSH tunnel if used remotely.
  def initialize(server: nil, username: nil, server_password: nil, db_name: nil, db_password: nil)
    if server
      @gateway = Net::SSH::Gateway.new(server, username, password: server_password)
      port = @gateway.open('127.0.0.1', 3306, 3306)
      host = '127.0.0.1'
    else
      # If the bot is running on the same server like the database.
      host = 'localhost'
    end

    @database = Sequel.connect(
      adapter:  'mysql2',
      host:     host,
      username: username,
      database: db_name,
      password: db_password,
      port:     port
    )
  end

  # Creates a table, if it doesn't already exist, with the given columns.
  def create_table(table_name, columns = {})
    @database.create_table?(table_name) do
      # primary_key :id
      columns.each do |column_name, datatype|
        # Not pretty, but the only way to actually get it to store IDs correctly.
        datatype == Integer ? (Bignum column_name) : (column column_name, datatype)
      end
    end
  end

  def close
    @gateway.shutdown!
  end

  # Outputs everything on the database related to the server. Just for debugging.
  def test_output(table_name)
    puts @database[table_name].select.all
  end

  def schema(table_name)
    puts @database.schema(table_name)
  end

  # Returns all the non-nil values of a column as an array.
  def read_column(table_name, column)
    @database[table_name].select(column).where(column => !nil).map(&:values).flatten
  end

  # Returns the first value of a column. Only used for columns that really only store one value.
  def read_value(table_name, column)
    read_column(table_name, column).first
  end

  # Used to update the value in a column that really only stores on value.
  # If there was no value to update, inserts the value instead
  def update_value(table_name, column, value)
    affected_rows = @database[table_name].where(column => !nil).update(column => value)
    unique_insert(table_name, column, value) if affected_rows.zero?
  end

  # Inserts value if it doesn't exist for given server ID.
  # Returns true if the insert was successful, false if a duplicate was found
  # Look into what some guy said on the discord API server to maybe safe an "if" here
  def unique_insert(table_name, column, value)
    if read_column(table_name, column).include?(value)
      false
    else
      @database[table_name].insert(column => value)
      true
    end
  end

  # Removes the row with a given server ID and a given value in a given column.
  def delete_value(table_name, column, value)
    if read_column(table_name, column).include?(value)
      @database[table_name].where(column => value).delete
      true
    else
      false
    end
  end

  # Deletes all values in the table for a given server.
  def delete_server_values(server_id)
    @database.drop_table?("ssb_server_#{server_id}".to_sym)
  end

  # Sets the default values for the log- and assignment-channel, if they don't already have values.
  def init_default_values(server)
    init_assignment_channel(server) unless read_value("ssb_server_#{server.id}".to_sym, :assignment_channel)
    LOGGER.default_log_channel(server)
  end

  private

  def init_assignment_channel(server)
    # Assignment channel defaults to the rules channel...
    assignment_channel = server.channels.find { |channel| channel.name.include?('rules') }
    # ...or the top channel, if there is no rules channel.
    assignment_channel ||= server.channels.sort_by { |c| [c.position, c.id] }[1]

    unique_insert("ssb_server_#{server.id}".to_sym, :assignment_channel, assignment_channel.id)
  end
end
