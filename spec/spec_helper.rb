$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'sequel'
require 'sequel_sluggable'
require 'spec'
require 'spec/autorun'

DB = Sequel.sqlite
DB.create_table :items do
  primary_key :id
  String :name
  String :slug
end

class Item < Sequel::Model; end

Spec::Runner.configure do |config|
  config.after(:each)  { Item.delete }
end
