version = ActiveRecord::VERSION::STRING

if version >= '4.2.'
  require_relative 'compat/4.2'
else
  begin
    require 'foreigner'
  rescue LoadError
    $stderr.puts <<-ERR.strip_heredoc

      ERROR: immigrant requires the foreigner gem (unless you are on rails 4.2+)

      To fix this, add the following to your Gemfile:

        gem "foreigner", "~> 1.2"

      Or just upgrade rails ;) ... lol, "just"

    ERR
    exit 1
  end
  Foreigner.load

  require_relative 'compat/foreigner_extensions'

  if version >= '4.0'
    require_relative 'compat/4.0'
  elsif version >= '3.1'
    require_relative 'compat/3.1'
  else
    require_relative 'compat/3.0'
  end
end

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
