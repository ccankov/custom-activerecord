require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    @class_name.downcase + 's'
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options[:foreign_key] || :"#{name}_id"
    @class_name = options[:class_name] || name.to_s.capitalize
    @primary_key = options[:primary_key] || :id
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = options[:foreign_key] || :"#{self_class_name.downcase}_id"
    @class_name = options[:class_name] || name.to_s.capitalize.singularize
    @primary_key = options[:primary_key] || :id
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    define_method(name) do
      pkey = options.send(:primary_key)
      fkey = options.send(:foreign_key)
      target_class = options.model_class
      records = target_class.where(pkey => send(fkey))

      return nil if records.empty?
      options.model_class.new(records.first.attributes)
    end
    assoc_options[name] = options
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.name, options)
    define_method(name) do
      pkey = options.send(:primary_key)
      fkey = options.send(:foreign_key)
      target_class = options.model_class
      records = target_class.where(fkey => send(pkey))

      return [] if records.empty?
      results = []
      records.each do |record|
        results << options.model_class.new(record.attributes)
      end
      results
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
