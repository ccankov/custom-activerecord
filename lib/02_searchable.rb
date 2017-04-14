require_relative 'db_connection'
require_relative '01_sql_object'
require_relative 'relation'

module Searchable
  def where(params)
    Relation.new(table_name, params, self)
  end
end

class SQLObject
  extend Searchable
end
