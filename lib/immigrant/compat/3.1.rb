module Immigrant
  ForeignKeyDefinition = ::Foreigner::ConnectionAdapters::ForeignKeyDefinition

  TEMPLATE = 'immigration.rb.erb'
  FOREIGN_KEY = :foreign_key
  ON_DELETE = :dependent

  def self.qualified_reflection?(reflection, klass)
    reflection.options[:conditions].present?
  end
end

