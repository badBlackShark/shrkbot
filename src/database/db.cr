require "db"
require "pg"

class Db
  getter db : DB::Database

  def initialize
    # db = DB.open("postgres://root:password@localhost:5678/shrkbot_db") # dev
    db = DB.open("postgres://root:password@db:5432/shrkbot_db") # production

    @db = db.not_nil!
  end

  def close
    @db.close
  end

  def create_table(name : String, columns : Array(String))
    @db.exec("create table if not exists #{name} (#{columns.join(", ")})")
  end

  def get_row(table : String, column : String, value, types : Tuple)
    @db.query_one?("select * from #{table} where #{column} = #{value} limit 1", as: types)
  end

  def get_rows(table : String, column : String, value)
    @db.query("select * from #{table} where #{column} = #{value}")
  end

  def delete_row(table : String, column : String, value)
    @db.exec("delete from #{table} where #{column} = #{value}")
  end

  def delete_row_double_filter(table : String, filter1 : String, value1, filter2 : String, value2)
    @db.exec("delete from #{table} where #{filter1} = #{value1} and #{filter2} = #{value2}")
  end

  def get_value(table : String, column : String, filter : String, value, klass : Class)
    @db.query_one?("select #{column} from #{table} where #{filter} = #{value} limit 1", as: klass)
  end

  def update_value(table : String, column : String, value, filter : String, filter_value)
    @db.exec("update #{table} set #{column} = ($1) where #{filter} = #{filter_value}", value)
  end

  def exec(command : String)
    @db.exec(command)
  end

  def insert_row(table : String, values)
    placeholders = Array(String).new
    values.size.times { |i| placeholders << "$#{i + 1}" }
    placeholders = "(" + placeholders.join(", ") + ")"

    @db.exec("insert into #{table} values #{placeholders}", args: values)
  end

  def get_table(table : String, types : Tuple)
    res = Array(String | Int64).new
    tmp = @db.query_one("select * from #{table} limit 1", as: types)
    tmp
  end
end
