require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]
      middle_obj = self.send(through_name)
      records = DBConnection.execute(<<-SQL, middle_obj.send(source_options.send(:primary_key)))
        SELECT
          #{source_options.table_name}.*
        FROM
          #{through_options.table_name}
          JOIN
            #{source_options.table_name} ON #{through_options.table_name}.#{source_options.send(:foreign_key)} = #{source_options.table_name}.#{source_options.send(:primary_key)}
        WHERE
          #{through_options.table_name}.#{source_options.send(:primary_key)} = ?
      SQL

      return nil if records.length.zero?
      source_options.model_class.new(records.first)
    end
  end
end
