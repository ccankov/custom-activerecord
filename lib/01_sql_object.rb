require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    @cols ||= (DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    )[0].map(&:to_sym)
  end

  def self.finalize!
    columns.each do |col_name|
      define_method(col_name) do
        attributes[col_name]
      end

      setter_name = "#{col_name}=".to_sym
      define_method(setter_name) do |value|
        attributes[col_name] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name.nil? ? self.name.tableize : @table_name
  end

  def self.all
    all_records = DBConnection.execute(<<-SQL)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
    SQL
    parse_all(all_records)
  end

  def self.parse_all(results)
    arr_results = []
    results.each do |result|
      arr_results << new(result)
    end
    arr_results
  end

  def self.find(id)
    record = DBConnection.execute(<<-SQL, id)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL
    return nil if record.length.zero?
    new(record.first)
  end

  def initialize(params = {})
    params.each do |key, val|
      key = key.to_sym
      raise "unknown attribute '#{key}'" unless self.class.columns.include?(key)
      setter_name = "#{key}=".to_sym
      send(setter_name, val)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    attributes.values
  end

  def insert
    columns = self.class.columns[1..-1]
    col_names = columns.join(', ')
    question_marks = ['?'] * columns.length
    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks.join(', ')})
    SQL

    attributes[:id] = DBConnection.last_insert_row_id
  end

  def update
    columns = self.class.columns[1..-1]
    col_values = columns.map { |col| "#{col} = ?" }.join(', ')
    DBConnection.execute(<<-SQL, *attribute_values[1..-1], attribute_values[0])
      UPDATE
        #{self.class.table_name}
      SET
        #{col_values}
      WHERE
        id = ?
    SQL

    attributes[:id] = DBConnection.last_insert_row_id
  end

  def save
    attribute_values[0] ? update : insert
  end
end
