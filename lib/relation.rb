require_relative 'db_connection'

class Relation
  def initialize(params, klass)
    @data = nil
    @klass = klass
    @params = params
    where_clause = params.map { |key, _| "#{key} = ?" }.join(' AND ')
    @query = <<-SQL
      SELECT
        *
      FROM
        #{@klass.table_name}
      WHERE
        #{where_clause}
    SQL
  end

  def where(params)
    params = @params.merge(params)
    self.class.new(params, @klass)
  end

  def method_missing(method_name, *args, &block)
    load.send(method_name, *args, &block)
  end

  def load
    return @data if @data
    puts "Running: #{@query.delete("\n")}"
    records = DBConnection.execute(<<-SQL, *@params.values)
      #{@query}
    SQL
    return [] if records.length.zero?
    @data = @klass.parse_all(records)
  end
end
