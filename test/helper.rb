require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

require 'test/unit'
require 'active_record'

require 'foreigner'
class Foreigner::Adapter
  def self.configured_name; "dummy_adapter"; end
end
Foreigner.load

require 'immigrant'
Immigrant.load

module TestMethods
  def foreign_key_definition(*args)
    Foreigner::ConnectionAdapters::ForeignKeyDefinition.new(*args)
  end
end
