require 'rake'

desc 'Default: run unit tests.'
task :default => :test

require 'rake/testtask'
desc 'Test the immigrant plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end