module Immigrant
  module ForeignKeyExtensions
    include Foreigner::SchemaDumper::ClassMethods

    def self.included(klass)
      def initialize(from_table, to_table, options)
        options.delete(:on_update)
        options[:dependent] = normalize_dependent(options.delete(:on_delete))
        super
      end

      def normalize_dependent(value)
        case value
        when :cascade then :delete
        else value
        end
      end
    end
  end
end
