module Immigrant
  ForeignKeyDefinition = ::Foreigner::ConnectionAdapters::ForeignKeyDefinition

  TEMPLATE = 'immigration.rb.erb'
  FOREIGN_KEY = :foreign_key
  ON_DELETE = :dependent

  def self.qualified_reflection?(reflection, klass)
    scope = reflection.scope
    if scope.nil?
      false
    elsif scope.respond_to?(:options)
      scope.options[:where].present?
    else
      klass.instance_exec(*([nil]*scope.arity), &scope).where_values.present?
    end
  rescue
    # if there's an error evaluating the scope block or whatever, just
    # err on the side of caution and assume there are conditions
    true
  end
end
