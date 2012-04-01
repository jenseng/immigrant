require 'active_support/all'
require 'foreigner'

module Immigrant
  extend ActiveSupport::Autoload
  autoload :Loader
  autoload :ForeignKeyDefinition

  class << self
    def infer_keys(db_keys = current_foreign_keys, classes = model_classes)
      database_keys = db_keys.inject({}) { |hash, foreign_key|
        hash[foreign_key.hash_key] = foreign_key
        hash
      }
      model_keys, warnings = model_keys(classes)
      new_keys = []
      model_keys.keys.each do |hash_key|
        foreign_key = model_keys[hash_key]
        # if the foreign key exists in the db, we call it good (even if
        # the name is different or :dependent doesn't match), though 
        # we do warn on clearly broken stuff
        if current_key = database_keys[hash_key]
          if current_key.to_table != foreign_key.to_table || current_key.options[:primary_key] != foreign_key.options[:primary_key]
            warnings[hash_key] = "Skipping #{foreign_key.from_table}.#{foreign_key.options[:column]}: its association references a different key/table than its current foreign key"
          end
        else
          new_keys << foreign_key
        end
      end
      [new_keys.sort_by{ |key| key.options[:name] }, warnings]
    end

    private

      def current_foreign_keys
        ActiveRecord::Base.connection.tables.map{ |table|
          ActiveRecord::Base.connection.foreign_keys(table)
        }.flatten
      end

      def model_classes
        classes = []
        pattern = /^\s*(has_one|has_many|has_and_belongs_to_many|belongs_to)\s/
        Dir['app/models/*.rb'].each do |model|
          class_name = model.sub(/\A.*\/(.*?)\.rb\z/, '\1').camelize
          begin
            klass = class_name.constantize
          rescue SyntaxError, LoadError
            if File.read(model) =~ pattern
              raise "unable to load #{class_name} and its associations"
            end
            next
          end
          classes << klass if klass < ActiveRecord::Base
        end
        classes
      end

      def model_keys(classes)
        # see what the models say there should be
        foreign_keys = {}
        warnings = {}
        classes.map{ |klass|
          foreign_keys_for(klass)
        }.flatten.uniq.each do |foreign_key|
          # we may have inferred it from several different places, e.g.
          #    Bar.belongs_to :foo
          #    Foo.has_many :bars
          #    Foo.has_many :bazzes, :class_name => Bar
          # we need to make sure everything is legit and see if any of them
          # specify :dependent => :delete
          if current_key = foreign_keys[foreign_key.hash_key]
            if current_key.to_table != foreign_key.to_table || current_key.options[:primary_key] != foreign_key.options[:primary_key]
              warnings[foreign_key.hash_key] ||= "Skipping #{foreign_key.from_table}.#{foreign_key.options[:column]}: it has multiple associations referencing different keys/tables."
              next
            else
              next unless foreign_key.options[:dependent]
            end
          end
          foreign_keys[foreign_key.hash_key] = foreign_key
        end
        warnings.keys.each { |hash_key| foreign_keys.delete(hash_key) }
        [foreign_keys, warnings]
      end

      def foreign_keys_for(klass)
        fk_method = ActiveRecord::VERSION::STRING < '3.1.' ? :primary_key_name : :foreign_key

        klass.reflections.values.reject{ |reflection|
          # some associations can just be ignored, since:
          # 1. we aren't going to parse SQL
          # 2. foreign keys for :through associations will be handled by their
          #    component has_one/has_many/belongs_to associations
          # 3. :polymorphic(/:as) associations can't have foreign keys
          (reflection.options.keys & [:finder_sql, :through, :polymorphic, :as]).present?
        }.map { |reflection|
          begin
            case reflection.macro
              when :belongs_to
                Foreigner::ConnectionAdapters::ForeignKeyDefinition.new(
                  klass.table_name, reflection.klass.table_name,
                  :column => reflection.send(fk_method).to_s,
                  :primary_key => reflection.klass.primary_key.to_s,
                  # although belongs_to can specify :dependent, it doesn't make
                  # sense from a foreign key perspective
                  :dependent => nil
                )
              when :has_one, :has_many
                Foreigner::ConnectionAdapters::ForeignKeyDefinition.new(
                  reflection.klass.table_name, klass.table_name,
                  :column => reflection.send(fk_method).to_s,
                  :primary_key => klass.primary_key.to_s,
                  :dependent => [:delete, :delete_all].include?(reflection.options[:dependent]) && reflection.options[:conditions].nil? ? :delete : nil
                )
              when :has_and_belongs_to_many
                [
                  Foreigner::ConnectionAdapters::ForeignKeyDefinition.new(
                    reflection.options[:join_table], klass.table_name,
                    :column => reflection.send(fk_method).to_s,
                    :primary_key => klass.primary_key.to_s,
                    :dependent => nil
                  ),
                  Foreigner::ConnectionAdapters::ForeignKeyDefinition.new(
                    reflection.options[:join_table], reflection.klass.table_name,
                    :column => reflection.association_foreign_key.to_s,
                    :primary_key => reflection.klass.primary_key.to_s,
                    :dependent => nil
                  )
                ]
            end
          rescue NameError # e.g. belongs_to :oops_this_is_not_a_table
            []
          end
        }.flatten
      end

  end
end

require 'immigrant/loader'
require 'immigrant/railtie' if defined?(Rails)