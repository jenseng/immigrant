module Immigrant
  class KeyValidator
    def valid?(key)
      tables = connection.tables
      return false unless tables.include?(key.from_table)
      return false unless tables.include?(key.to_table)
      return false unless column_exists?(key.from_table, key.options[:column])
      return false unless column_exists?(key.to_table, key.options[:primary_key])
      return false unless key.options[:primary_key] == "id" || has_unique_index?(key.to_table, key.options[:primary_key])
      true
    end

   private

    def has_unique_index?(table_name, column_name)
      connection.indexes(table_name).any? { |index| index.columns == [column_name] && index.unique && index.where.nil? }
    end

    def column_exists?(table_name, column_name)
      columns_for(table_name).any? { |column| column.name == column_name }
    end

    def columns_for(table_name)
      @columns ||= {}
      @columns[table_name] ||= connection.columns(table_name)
    end

    def connection
      @connection ||= ActiveRecord::Base.connection
    end
  end
end
