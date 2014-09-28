require 'rails/generators/active_record'

class ImmigrationGenerator < ActiveRecord::Generators::Base
  def create_immigration_file
    Rails.application.eager_load!
    @keys, warnings = Immigrant.infer_keys
    warnings.values.each{ |warning| $stderr.puts "WARNING: #{warning}" }
    @keys.each do |key|
      next unless key.options[:dependent] == :delete
      $stderr.puts "NOTICE: #{key.options[:name]} has ON DELETE CASCADE. You should remove the :dependent option from the association to take advantage of this."
    end
    if @keys.present?
      migration_template Immigrant::TEMPLATE, "db/migrate/#{file_name}.rb"
    else
      puts 'Nothing to do'
    end
  end

  source_root File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
end
