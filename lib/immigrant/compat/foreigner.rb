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

module Immigrant
  ForeignKeyDefinition = ::Foreigner::ConnectionAdapters::ForeignKeyDefinition

  module ForeignKeyExtensions
    include Foreigner::SchemaDumper::ClassMethods

    def self.included(klass)
      # ForeignKeyExtensions already overrides initialize; override it
      # some more
      klass.send(:include, Module.new{
        def initialize(from_table, to_table, options)
          options.delete(:on_update)
          options[:dependent] ||= normalize_dependent(options.delete(:on_delete))
          super
        end
      })
    end

    def normalize_dependent(value)
      case value
      when :cascade then :delete
      else value
      end
    end
  end
end
