# add some useful things for querying/comparing/dumping foreign keys
module Immigrant
  module ForeignKeyExtensions
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
