require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    data = DBConnection.execute(<<-SQL)
      SELECT *
      FROM #{table_name}
      WHERE #{param_k_v_string(params)}
    SQL
    data.map { |info| new(info) }
  end

  def param_k_v_string(params)
    str = []
    params.keys.each do |key|
      val = params[key].class == Integer ? params[key] : "'#{params[key]}'"
      str << "#{key}=#{val}"
    end
    str.join(" AND ")
  end

  def param_val_string(params)
    return params unless params.is_a? Hash
    str = []
    params.keys.each do |key|
    end
  end
end

class SQLObject
  extend Searchable
end
