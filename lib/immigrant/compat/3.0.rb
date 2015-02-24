require_relative 'foreigner'

module Immigrant
  TEMPLATE = 'immigration-pre-3.1.rb.erb'
  FOREIGN_KEY = :primary_key_name

  class KeyFinder
    def qualified_reflection?(reflection, klass)
      reflection.options[:conditions].present?
    end
  end
end
