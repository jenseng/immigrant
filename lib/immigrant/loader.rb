module Immigrant
  def self.load
    require "active_record"
    require_relative "compat"

    ForeignKeyDefinition.send :include, ForeignKeyExtensions
  end
end
