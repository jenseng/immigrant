require "active_record/connection_adapters/abstract/schema_definitions"

module Immigrant
  ForeignKeyDefinition = ::ActiveRecord::ConnectionAdapters::ForeignKeyDefinition

  TEMPLATE = 'immigration.rb.erb'
  FOREIGN_KEY = :foreign_key

  module ForeignKeyExtensions
    # DRY alert: copied from ActiveRecord::SchemaDumper#foreign_keys
    def dump_foreign_key(foreign_key)
      parts = [
        "add_foreign_key #{remove_prefix_and_suffix(foreign_key.from_table).inspect}",
        remove_prefix_and_suffix(foreign_key.to_table).inspect,
      ]

      if foreign_key.column != foreign_key_column_for(foreign_key.to_table)
        parts << "column: #{foreign_key.column.inspect}"
      end

      if foreign_key.custom_primary_key?
        parts << "primary_key: #{foreign_key.primary_key.inspect}"
      end

      if foreign_key.name !~ /^fk_rails_[0-9a-f]{10}$/
        parts << "name: #{foreign_key.name.inspect}"
      end

      parts << "on_update: #{foreign_key.on_update.inspect}" if foreign_key.on_update
      parts << "on_delete: #{foreign_key.on_delete.inspect}" if foreign_key.on_delete

      "  #{parts.join(', ')}"
    end


    def remove_prefix_and_suffix(table)
      table.gsub(/^(#{ActiveRecord::Base.table_name_prefix})(.+)(#{ActiveRecord::Base.table_name_suffix})$/,  "\\2")
    end

    def foreign_key_column_for(table_name)
      "#{table_name.to_s.singularize}_id"
    end
  end
end
