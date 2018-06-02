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
      columns.each do |column_name, datatype|
        column column_name, datatype
      end
    end
  end

  def close
    @gateway.shutdown!
  end

  # Returns all the non-nil values of a column as an array.
  def read_column(table_name, column)
    @database[table_name].select(column).map(&:values).flatten.compact
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

  # Regular update_value doesn't work for Strings.
  # For some reason, it classifies those rows as nil.
  def update_string_value(table_name, column, value)
    old_value = read_column(table_name, column).join(' ')
    @database[table_name].where(column => old_value).delete
    unique_insert(table_name, column, value)
  end

  # Inserts value if it doesn't exist for given server ID.
  # Returns true if the insert was successful, false if a duplicate was found
  def unique_insert(table_name, column, value)
    if read_column(table_name, column).include?(value)
      false
    else
      @database[table_name].insert(column => value)
      true
    end
  end

  # Removes the row with a given value in a given column.
  # Returns whether or not something was actually deleted.
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
    @database.drop_table?("shrk_server_#{server_id}".to_sym)
  end

  # Insert a row into a table (assumes you know what the columns are!)
  def insert_row(table_name, values)
    @database[table_name].insert(values)
  end

  # Select rows, based on one filter column
  def select_rows(table_name, column, value)
    @database[table_name].where(column => value).all
  end

  # Updates a row. The first value is assumed to be the primary key.
  def update_row(table_name, values)
    @database[table_name].where(@database[table_name].columns.first => values.first).delete
    @database[table_name].insert(values)
  end

  # Updates a row. The first two values are assumed to be the primary keys.
  def update_row_double_key(table_name, values)
    @database[table_name].where(@database[table_name].columns.first => values.first)
                         .where(@database[table_name].columns[1] => values[1]).delete
    @database[table_name].insert(values)
  end

  # Returns the whole table
  def read_all(table_name)
    @database[table_name].all
  end

  # Sets the default values for the log- and assignment-channel, if they don't already have values.
  def init_default_values(server)
    LOGGER.init_log_channel(server)
    RoleMessage.init_assignment_channel(server)
    JoinLeaveMessages.init_message_channel(server)
  end
end
