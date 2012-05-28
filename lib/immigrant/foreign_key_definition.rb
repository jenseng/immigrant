module Immigrant
  # add some useful stuff to foreigner's ForeignKeyDefinition
  # TODO: get more of this into foreigner so we don't need to monkey patch
  module ForeignKeyDefinition
    include Foreigner::SchemaDumper::ClassMethods

    def initialize(from_table, to_table, options, *args)
      options ||= {}
      options[:name] ||= "#{from_table}_#{options[:column]}_fk"
      super(from_table, to_table, options, *args)
    end

    def hash_key
      [from_table, options[:column]]
    end

    def to_ruby(action = :add)
      if action == :add
        dump_foreign_key(self)
      else
        "remove_foreign_key #{from_table.inspect}, " \
        ":name => #{options[:name].inspect}"
      end
    end
  end
end