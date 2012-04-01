class <%= migration_class_name %> < ActiveRecord::Migration
  def self.up
<% @keys.each do |key| -%>
    <%= key.to_ruby(:add) %>
<%- end -%>
  end

  def self.down
<% @keys.each do |key| -%>
    <%= key.to_ruby(:remove) %>
<%- end -%>
  end
end
