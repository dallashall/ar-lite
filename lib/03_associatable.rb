require_relative "02_searchable"
require "active_support/inflector"

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
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions # :nodoc:
  def initialize(name, options = {})
    options[:foreign_key] ||= "#{name.to_s.singularize}_id".to_sym
    options[:primary_key] ||= :id
    options[:class_name] ||= name.to_s.camelize.singularize
    options.each do |key, value|
      send("#{key}=", value)
    end
  end
end

class HasManyOptions < AssocOptions # :nodoc:
  def initialize(name, self_class_name, options = {})
    options[:foreign_key] ||= "#{self_class_name.to_s.downcase.singularize.underscore}_id".to_sym
    options[:primary_key] ||= :id
    options[:class_name] ||= name.to_s.singularize.camelize
    options.each do |key, value|
      send("#{key}=", value)
    end
  end
end

module Associatable # :nodoc:
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options.to_h)
    define_method(name) do
      f_key = send(options.foreign_key)
      target_class = options.model_class
      target_class.where(id: f_key).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, to_s, options.to_h)
    define_method(name) do
      target_class = options.model_class
      target_class.where(options.foreign_key => send(options.primary_key))
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject # :nodoc:
  extend Associatable
end
