require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

require 'minitest/autorun'

require 'active_record'
require_relative "compat"

require 'immigrant'
Immigrant.load

module TestMethods
  def foreign_key_definition(*args)
    Immigrant::ForeignKeyDefinition.new(*args)
  end
end
