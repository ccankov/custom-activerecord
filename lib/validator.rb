require_relative 'db_connection'
require_relative '04_associatable2'

class Validator
  attr_reader :property

  def initialize(property, type)
    @property = property
    @type = type
  end

  def validate!(object)
    validation_method = "validate_#{@type}".to_sym
    send(validation_method, object)
  end

  def validate_presence(object)
    object.send(@property).nil? ? "#{property} cannot be nil" : nil
  end
end

module Validatable
  def validates(property, options = {})
    raise "Validation options missing for '#{property}'" if options.empty?
    options.each do |type, value|
      validators << Validator.new(property, type) if value
    end
    define_method(:errors) do
      @errors = Hash.new { |hash, key| hash[key] = [] }
      self.class.validators.each do |validator|
        validation_result = validator.validate!(self)
        @errors[validator.property] << validation_result if validation_result
      end
      @errors
    end

    define_method(:full_messages) do
      errors.values.flatten
    end

    define_method(:valid?) do
      full_messages.empty?
    end
  end

  def validators
    @validators ||= []
  end
end

class SQLObject
  extend Validatable
end
