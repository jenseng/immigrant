namespace :immigrant do
  desc 'Checks for missing foreign key relationships in the database'
  task check_keys: :environment do
    Rails.application.eager_load!

    keys, warnings = Immigrant::KeyFinder.new.infer_keys
    warnings.values.each { |warning| $stderr.puts "WARNING: #{warning}" }

    keys.each do |key|
      column = key.options[:column]
      pk = key.options[:primary_key]
      $stderr.puts "Missing foreign key relationship on '#{key.from_table}.#{column}' to '#{key.to_table}.#{pk}'"
    end

    if keys.any?
      puts 'Found missing foreign keys, run `rails generate immigration MigrationName` to create a migration to add them.'
      exit keys.count
    end
  end
end
