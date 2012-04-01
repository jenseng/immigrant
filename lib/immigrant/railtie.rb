module Immigrant
  class Railtie < Rails::Railtie
    initializer 'immigrant.load' do
      # TODO: implement hook in Foreigner and use that instead
      ActiveSupport.on_load :active_record do
        Immigrant.load
      end
    end
    generators do
      require "generators/immigration_generator"
    end
  end
end