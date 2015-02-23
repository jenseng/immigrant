module Immigrant
  ForeignKeyDefinition = ::Foreigner::ConnectionAdapters::ForeignKeyDefinition

  TEMPLATE = 'immigration.rb.erb'
  FOREIGN_KEY = :foreign_key

  class KeyFinder
    def qualified_reflection?(reflection, klass)
      reflection.options[:conditions].present?
    end
  end
end

