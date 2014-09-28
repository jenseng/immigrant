if ActiveRecord::VERSION::STRING < '4.2.'
  require "foreigner"

  class Foreigner::Adapter
    def self.configured_name; "dummy_adapter"; end
    def self.load!; end
  end
end
