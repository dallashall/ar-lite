require_relative "db_connection"
require "active_support/inflector"
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject # :nodoc:
  def self.columns
    @columns ||= DBConnection.execute2(
      "SELECT * FROM #{table_name} LIMIT 0"
    ).first.map(&:to_sym)
  end

  def self.finalize!
    columns.each do |col_sym|
      define_method("#{col_sym}=") { |val| attributes[col_sym] = val }
      define_method(col_sym) { attributes[col_sym] }
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= to_s.tableize
  end

  def self.all
    parse_all(DBConnection.execute("SELECT * FROM #{table_name}"))
  end

  def self.parse_all(results)
    results.map do |options_hash|
      new(options_hash)
    end
  end

  def self.find(id)
    data = DBConnection.execute(<<-SQL, id)
      SELECT *
      FROM #{table_name}
      WHERE id = ?
    SQL
    parse_all(data).first
  end

  def initialize(params = {})
    params.each do |attr_name, v|
      attr_name = attr_name.to_sym
      raise "unknown attribute '#{attr_name}'" unless self.class.columns.include?(attr_name)
      send("#{attr_name}=", v)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    @attributes.values
  end

  def insert
    return update if id
    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{table_name} (#{attributes.keys.join(',')})
      VALUES
        (#{q_marks(@attributes)})
    SQL
    send("id=", DBConnection.last_insert_row_id)
    self
  end

  def update
    return insert unless id
    DBConnection.execute(<<-SQL, attributes[:id])
      UPDATE #{table_name}
      SET #{attributes_k_v_string}
      WHERE id = ?
    SQL
    self
  end

  def save
    id ? update : insert
  end

  def attributes_keys_string
    attributes.keys.join(",")
  end

  def attributes_k_v_string
    str = []
    attributes.keys.each do |key|
      val = attributes[key].class == Integer ? attributes[key] : "'#{attributes[key]}'"
      str << "#{key}=#{val}"
    end
    str.join(",")
  end

  def table_name
    self.class.table_name
  end

  def q_marks(vals)
    arr = []
    vals.length.times { arr << "?" }
    arr.join(",")
  end
end
