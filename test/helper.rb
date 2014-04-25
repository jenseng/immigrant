require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

require 'minitest/autorun'
require 'active_record'

require 'foreigner'
class Foreigner::Adapter
  def self.configured_name; "dummy_adapter"; end
  def self.load!; end
end
Foreigner.load

require 'immigrant'
Immigrant.load

module TestMethods
  def foreign_key_definition(*args)
    Foreigner::ConnectionAdapters::ForeignKeyDefinition.new(*args)
  end
end
