require_relative 'db_connection'
require 'byebug'

class Relation
  def initialize(table_name, params, klass)
    @klass = klass
    @table_name = table_name
    @params = params
    where_clause = params.map { |key, _| "#{key} = ?" }.join(' AND ')
    @query = <<-SQL
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{where_clause}
    SQL
  end

  def where(params)
    params = @params.merge(params)
    self.class.new(@table_name, params, @klass)
  end

  def method_missing(method_name, *args, &block)
    load.send(method_name, *args, &block)
  end

  def load
    records = DBConnection.execute(<<-SQL, *@params.values)
      #{@query}
    SQL
    return [] if records.length.zero?
    @klass.parse_all(records)
  end
end
