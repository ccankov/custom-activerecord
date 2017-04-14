require_relative 'db_connection'
require_relative '01_sql_object'

module Validatable
  def validates(property, options = {})
    raise "Validation options missing for '#{property}'" if options.empty?
    method_name = "#{property}_validation"
  end

  def validation_methods
    @validation_methods ||= {}
  end
end

class SQLObject
  extend Validatable
end
