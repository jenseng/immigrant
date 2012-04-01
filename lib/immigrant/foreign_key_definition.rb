module Immigrant
  # add some useful stuff to foreigner's ForeignKeyDefinition
  # TODO: get it in foreigner so we don't need to monkey patch
  module ForeignKeyDefinition
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
        # not DRY ... guts of this are copied from Foreigner :(
        parts = [ ('add_foreign_key ' + from_table.inspect) ]
        parts << to_table.inspect
        parts << (':name => ' + options[:name].inspect)
  
        if options[:column] != "#{to_table.singularize}_id"
          parts << (':column => ' + options[:column].inspect)
        end
        if options[:primary_key] != 'id'
          parts << (':primary_key => ' + options[:primary_key].inspect)
        end
        if options[:dependent].present?
          parts << (':dependent => ' + options[:dependent].inspect)
        end
        parts.join(', ')
      else
        "remove_foreign_key #{from_table.inspect}, " \
        ":name => #{options[:name].inspect}"
      end
    end
  end
end