version = ActiveRecord::VERSION::STRING

if version >= '5.0.'
  require_relative 'compat/5.0'
elsif version >= '4.2.'
  require_relative 'compat/4.2'
elsif version >= '4.0'
  require_relative 'compat/4.0'
elsif version >= '3.1'
  require_relative 'compat/3.1'
else
  require_relative 'compat/3.0'
end
