module Immigrant
  def self.load
    Foreigner::ConnectionAdapters::ForeignKeyDefinition.instance_eval do
      include Immigrant::ForeignKeyDefinition
    end
  end
end