require 'helper'

class ImmigrantTest < ActiveSupport::TestCase
  include TestMethods

  ActiveRecord::Base.instance_eval do
    def primary_key
      connection.primary_key(table_name)
    end
    def connection
      @connection ||= MockConnection.new
    end

    if ActiveRecord::VERSION::STRING >= '4.'
      # support old 3.x syntax for the sake of concise tests
      extend(Module.new{
        [:belongs_to, :has_one, :has_many, :has_and_belongs_to_many].each do |method|
          define_method method do |assoc, scope = nil, options = {}|
            if scope.is_a?(Hash)
              options = scope
              scope_opts = options.extract!(:conditions, :order)
              scope = if scope_opts && scope_opts.present?
                lambda{ |_| where(scope_opts[:conditions]).order(scope_opts[:order]) }
              end
            end
            super assoc, scope, options
          end
        end
      })
    end
  end

  class MockConnection
    def supports_primary_key? # AR <3.2
      true
    end
    def primary_key(table)
      table.to_s !~ /s_.*s\z/ ? 'id' : nil
    end
  end

  def teardown
    subclasses = ActiveSupport::DescendantsTracker.direct_descendants(ActiveRecord::Base)
    subclasses.each do |subclass|
      subclass = subclass.to_s
      Object.send(:remove_const, subclass) if subclass =~ /\A[A-Z]/ && Object.const_defined?(subclass)
    end
    subclasses.replace([])
  end

  def given(code)
    # ugly little hack to get these temp classes not namespaced, so
    # that generated HM/BT from HABTM will find the right class
    Object.class_eval code
  end

  def infer_keys(db_keys = [])
    keys = Immigrant.infer_keys(db_keys).first
    # ensure each key generates correctly
    keys.each { |key| key.to_ruby(:add) }
    keys.sort_by { |key| [key.from_table, key.to_table] }
  end

  # basic scenarios

  test 'belongs_to should generate a foreign key' do
    given <<-CODE
      class Author < ActiveRecord::Base; end
      class Book < ActiveRecord::Base
        belongs_to :guy, :class_name => 'Author', :foreign_key => 'author_id'
      end
    CODE

    assert_equal(
      [foreign_key_definition(
         'books', 'authors',
         :column => 'author_id', :primary_key => 'id'
       )],
      infer_keys
    )
  end

  test 'has_one should generate a foreign key' do
    given <<-CODE
      class Author < ActiveRecord::Base
        has_one :piece_de_resistance, :class_name => 'Book', :order => "id DESC"
      end
      class Book < ActiveRecord::Base; end
    CODE

    assert_equal(
      [foreign_key_definition(
         'books', 'authors',
         :column => 'author_id', :primary_key => 'id'
       )],
      infer_keys
    )
  end

  test 'has_one :dependent => :delete should generate a foreign key with :on_delete => :cascade' do
    given <<-CODE
      class Author < ActiveRecord::Base
        has_one :book, :order => "id DESC", :dependent => :delete
      end
      class Book < ActiveRecord::Base; end
    CODE

    assert_equal(
      [foreign_key_definition(
         'books', 'authors',
         :column => 'author_id', :primary_key => 'id', :on_delete => :cascade, :on_update => :cascade
       )],
      infer_keys
    )
  end

  test 'has_many should generate a foreign key' do
    given <<-CODE
      class Author < ActiveRecord::Base
        has_many :babies, :class_name => 'Book'
      end
      class Book < ActiveRecord::Base; end
    CODE

    assert_equal(
      [foreign_key_definition(
         'books', 'authors',
         :column => 'author_id', :primary_key => 'id'
       )],
      infer_keys
    )
  end

  test 'has_many :dependent => :delete_all should generate a foreign key with :on_delete => :cascade' do
    given <<-CODE
      class Author < ActiveRecord::Base
        has_many :books, :dependent => :delete_all
      end
      class Book < ActiveRecord::Base; end
    CODE

    assert_equal(
      [foreign_key_definition(
         'books', 'authors',
         :column => 'author_id', :primary_key => 'id', :on_delete => :cascade, :on_update => :cascade
       )],
      infer_keys
    )
  end

  test 'has_and_belongs_to_many should generate two foreign keys' do
    given <<-CODE
      class Author < ActiveRecord::Base
        has_and_belongs_to_many :fans
      end
      class Fan < ActiveRecord::Base; end
    CODE

    assert_equal(
      [foreign_key_definition(
         'authors_fans', 'authors',
         :column => 'author_id', :primary_key => 'id'
       ),
       foreign_key_definition(
         'authors_fans', 'fans',
         :column => 'fan_id', :primary_key => 'id'
       )],
      infer_keys
    )
  end

  test 'has_and_belongs_to_many should respect the join_table' do
    given <<-CODE
      class Author < ActiveRecord::Base
        has_and_belongs_to_many :fans, :join_table => :lols_wuts
      end
      class Fan < ActiveRecord::Base; end
    CODE

    assert_equal(
      [foreign_key_definition(
         'lols_wuts', 'authors',
         :column => 'author_id', :primary_key => 'id'
       ),
       foreign_key_definition(
         'lols_wuts', 'fans',
         :column => 'fan_id', :primary_key => 'id'
       )],
      infer_keys
    )
  end

  test 'conditional has_one/has_many associations should ignore :dependent' do
    given <<-CODE
      class Author < ActiveRecord::Base
        has_many :articles, :conditions => "published", :dependent => :delete_all
        has_one :favorite_book, :class_name => 'Book',
                :conditions => "most_awesome", :dependent => :delete
      end
      class Book < ActiveRecord::Base; end
      class Article < ActiveRecord::Base; end
    CODE

    assert_equal(
      [foreign_key_definition(
         'articles', 'authors',
         :column => 'author_id', :primary_key => 'id'
       ),
       foreign_key_definition(
         'books', 'authors',
         :column => 'author_id', :primary_key => 'id'
       )],
      infer_keys
    )
  end

  test 'primary_key should be respected' do
    given <<-CODE
      class User < ActiveRecord::Base
        has_many :emails, :primary_key => :email, :foreign_key => :to,
                 :dependent => :destroy
      end
      class Email < ActiveRecord::Base
        belongs_to :user, :primary_key => :email, :foreign_key => :to
      end
    CODE

    assert_equal(
      [foreign_key_definition(
        'emails', 'users',
        :column => 'to', :primary_key => 'email'
       )],
      infer_keys
    )
  end

  # (no) duplication

  test 'STI should not generate duplicate foreign keys' do
    given <<-CODE
      class Company < ActiveRecord::Base; end
      class Employee < ActiveRecord::Base
        belongs_to :company
      end
      class Manager < Employee; end
    CODE

    assert(Manager.reflections.present?)
    assert_equal(
      [foreign_key_definition(
         'employees', 'companies',
         :column => 'company_id', :primary_key => 'id'
       )],
      infer_keys
    )
  end

  test 'complementary associations should not generate duplicate foreign keys' do
    given <<-CODE
      class Author < ActiveRecord::Base
        has_many :books
      end
      class Book < ActiveRecord::Base
        belongs_to :author
      end
    CODE

    assert_equal(
      [foreign_key_definition(
         'books', 'authors',
         :column => 'author_id', :primary_key => 'id'
       )],
      infer_keys
    )
  end

  test 'redundant associations should not generate duplicate foreign keys' do
    given <<-CODE
      class Author < ActiveRecord::Base
        has_many :books
        has_many :favorite_books, :class_name => 'Book', :conditions => "awesome"
        has_many :bad_books, :class_name => 'Book', :conditions => "amateur_hour"
      end
      class Book < ActiveRecord::Base; end
    CODE

    assert_equal(
      [foreign_key_definition(
         'books', 'authors',
         :column => 'author_id', :primary_key => 'id'
       )],
      infer_keys
    )
  end


  # skipped associations

  test 'associations should not generate foreign keys if they already exist, even if :on_delete/name are different' do
    database_keys = [
      foreign_key_definition(
        'articles', 'authors',
        :column => 'author_id', :primary_key => 'id',
        :name => "doesn't_matter"
      ),
      foreign_key_definition(
        'books', 'authors', :column => 'author_id', :primary_key => 'id',
        :on_delete => :restrict, :on_update => :nullify
      )
    ]

    given <<-CODE
      class Author < ActiveRecord::Base
        has_many :articles
        has_one :favorite_book, :class_name => 'Book',
                :conditions => "most_awesome"
      end
      class Book < ActiveRecord::Base; end
      class Article < ActiveRecord::Base; end
    CODE

    assert_equal([], infer_keys(database_keys))
  end

  if ActiveRecord::VERSION::STRING < '4.'
    test 'finder_sql associations should not generate foreign keys' do
      given <<-CODE
        class Author < ActiveRecord::Base
          has_many :books, :finder_sql => <<-SQL
            SELECT *
            FROM books
            WHERE author_id = \\\#{id}
            ORDER BY RANDOM() LIMIT 5'
          SQL
        end
        class Book < ActiveRecord::Base; end
      CODE

      assert_equal([], infer_keys)
    end
  end

  test 'polymorphic associations should not generate foreign keys' do
    given <<-CODE
      class Property < ActiveRecord::Base
        belongs_to :owner, :polymorphic => true
      end
      class Person < ActiveRecord::Base
        has_many :properties, :as => :owner
      end
      class Corporation < ActiveRecord::Base
        has_many :properties, :as => :owner
      end
    CODE

    assert_equal([], infer_keys)
  end

  test 'has_many :through should not generate foreign keys' do
    given <<-CODE
      class Author < ActiveRecord::Base
        has_many :authors_fans
        has_many :fans, :through => :authors_fans
      end
      class AuthorsFan < ActiveRecord::Base
        belongs_to :author
        belongs_to :fan
      end
      class Fan < ActiveRecord::Base
        has_many :authors_fans
        has_many :authors, :through => :authors_fans
      end
    CODE

    assert_equal(
      [foreign_key_definition(
         'authors_fans', 'authors',
         :column => 'author_id', :primary_key => 'id'
       ),
       foreign_key_definition(
         'authors_fans', 'fans',
         :column => 'fan_id', :primary_key => 'id'
       )],
      infer_keys
    )
  end

  test 'broken associations should not cause errors' do
    given <<-CODE
      class Author < ActiveRecord::Base; end
      class Book < ActiveRecord::Base
        belongs_to :author
        belongs_to :invalid
      end
    CODE

    assert_equal(
      [foreign_key_definition(
         'books', 'authors',
         :column => 'author_id', :primary_key => 'id'
       )],
      infer_keys
    )
  end

  test 'abstract classes should not generate a foreign key' do
    given <<-CODE
      class User < ActiveRecord::Base; end
      class Widget < ActiveRecord::Base
        self.abstract_class = true

        belongs_to :user
      end
    CODE

    assert_equal([], infer_keys)
  end
end
