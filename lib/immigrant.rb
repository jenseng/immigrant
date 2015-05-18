require 'active_support/all'

module Immigrant
  class << self
    # expected format:
    # [{from_table: "the_table", column: "the_column"}, ...]"
    attr_writer :ignore_keys

    def ignore_keys
      @ignore_keys ||= []
    end
  end

  class KeyFinder
    def infer_keys(db_keys = current_foreign_keys, classes = model_classes)
      database_keys = Hash[db_keys.map { |foreign_key|
        [foreign_key.hash_key, foreign_key]
      }]

      ignore_keys = Hash[Immigrant.ignore_keys.map { |key|
        [[key[:from_table], key[:column]], true]
      }]

      model_keys, warnings = model_keys(classes)

      new_keys = []
      model_keys.keys.each do |hash_key|
        foreign_key = model_keys[hash_key]
        # if the foreign key exists in the db, we call it good (even if
        # the name is different or :on_delete doesn't match, etc.), though
        # we do warn on clearly broken stuff
        if current_key = database_keys[hash_key]
          if current_key.to_table != foreign_key.to_table || current_key.options[:primary_key] != foreign_key.options[:primary_key]
            warnings[hash_key] = "Skipping #{foreign_key.from_table}.#{foreign_key.options[:column]}: its association references a different key/table than its current foreign key"
          end
          next
        end

        next if ignore_keys[hash_key]
        next unless key_validator.valid?(foreign_key)

        new_keys << foreign_key
      end
      [new_keys.sort_by{ |key| key.options[:name] }, warnings]
    end

    private

      def key_validator
        @key_validator ||= KeyValidator.new
      end

      def tables
        @tables ||= ActiveRecord::Base.connection.tables
      end

      def current_foreign_keys
        tables.map{ |table|
          ActiveRecord::Base.connection.foreign_keys(table)
        }.flatten
      end

      def model_classes
        ActiveRecord::Base.descendants
      end

      def model_keys(classes)
        # see what the models say there should be
        foreign_keys = {}
        warnings = {}

        candidate_model_keys(classes).each do |foreign_key|
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

      def candidate_model_keys(classes)
        classes.inject([]) do |result, klass|
          result.concat foreign_keys_for(klass)
        end.uniq
      end

      def candidate_reflections_for(klass)
        klass.reflections.values.reject do |reflection|
          # some associations can just be ignored, since:
          # 1. we aren't going to parse SQL
          # 2. foreign keys for :through associations will be handled by their
          #    component has_one/has_many/belongs_to associations
          # 3. :polymorphic(/:as) associations can't have foreign keys
          (reflection.options.keys & [:finder_sql, :through, :polymorphic, :as]).present?
        end
      end

      def foreign_keys_for(klass)
        return [] if klass.abstract_class? || !tables.include?(klass.table_name)
        candidate_reflections_for(klass).inject([]) do |result, reflection|
          begin
            result.concat foreign_keys_for_reflection(klass, reflection)
          rescue NameError # e.g. belongs_to :oops_this_is_not_a_table
            result
          end
        end
      end

      def foreign_keys_for_reflection(klass, reflection)
        case reflection.macro
        when :belongs_to
          infer_belongs_to_keys(klass, reflection)
        when :has_one, :has_many
          infer_has_n_keys(klass, reflection)
        when :has_and_belongs_to_many
          infer_habtm_keys(klass, reflection)
        end || []
      end

      def infer_belongs_to_keys(klass, reflection)
        return if reflection.name == :left_side # redundant and unusable reflection automagically created by HABTM

        from_table = klass.table_name
        to_table = reflection.klass.table_name
        column = reflection.send(FOREIGN_KEY).to_s
        primary_key = (reflection.options[:primary_key] || reflection.klass.primary_key).to_s

        [
          ForeignKeyDefinition.new(
            from_table,
            to_table,
            :column => column,
            :primary_key => primary_key
            # although belongs_to can specify :dependent, it doesn't make
            # sense from a foreign key perspective, so no :on_delete
          )
        ]
      end

      def infer_has_n_keys(klass, reflection)
        from_table = reflection.klass.table_name
        to_table = klass.table_name
        column = reflection.send(FOREIGN_KEY).to_s
        primary_key = (reflection.options[:primary_key] || klass.primary_key).to_s

        actions = {}
        if [:delete, :delete_all].include?(reflection.options[:dependent]) && !qualified_reflection?(reflection, klass)
          actions = {:on_delete => :cascade, :on_update => :cascade}
        end

        [
          ForeignKeyDefinition.new(
            from_table,
            to_table,
            {
              :column => column,
              :primary_key => primary_key
            }.merge(actions)
          )
        ]
      end

      def infer_habtm_keys(klass, reflection)
        join_table = (reflection.respond_to?(:join_table) ? reflection.join_table : reflection.options[:join_table]).to_s

        left_to_table = klass.table_name
        left_column = reflection.send(FOREIGN_KEY).to_s
        left_primary_key = klass.primary_key.to_s

        right_to_table = reflection.klass.table_name
        right_column = reflection.association_foreign_key.to_s
        right_primary_key = reflection.klass.primary_key.to_s

        [
          ForeignKeyDefinition.new(
            join_table,
            left_to_table,
            :column => left_column,
            :primary_key => left_primary_key
          ),
          ForeignKeyDefinition.new(
            join_table,
            right_to_table,
            :column => right_column,
            :primary_key => right_primary_key
          )
        ]
      end


      def qualified_reflection?(reflection, klass)
        scope = reflection.scope
        if scope.nil?
          false
        else
          klass.instance_exec(*([nil]*scope.arity), &scope).where_clause.any?
        end
      rescue
        # if there's an error evaluating the scope block or whatever, just
        # err on the side of caution and assume there are conditions
        true
      end
  end
end

require 'immigrant/loader'
require 'immigrant/key_validator'
require 'immigrant/foreign_key_extensions'
require 'immigrant/railtie' if defined?(Rails)
