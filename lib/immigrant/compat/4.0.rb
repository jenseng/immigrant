module Immigrant
  ForeignKeyDefinition = ::Foreigner::ConnectionAdapters::ForeignKeyDefinition

  TEMPLATE = 'immigration.rb.erb'
  FOREIGN_KEY = :foreign_key
end
