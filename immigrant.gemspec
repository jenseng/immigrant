# -*- encoding: utf-8 -*-
 
Gem::Specification.new do |s|
  s.name = 'immigrant'
  s.version = '0.2.0'
  s.summary = 'Foreign key migration generator for Rails'
  s.description = 'Adds a generator for creating a foreign key migration based on your current model associations'

  s.required_ruby_version     = '>= 1.8.7'
  s.required_rubygems_version = '>= 1.3.5'

  s.author            = 'Jon Jensen'
  s.email             = 'jenseng@gmail.com'
  s.homepage          = 'http://github.com/jenseng/immigrant'

  s.files = %w(LICENSE.txt Rakefile README.md lib/generators/USAGE) + Dir['lib/**/*rb'] + Dir['test/**/*.rb']
  s.add_dependency('activerecord', '>= 3.0')
end
