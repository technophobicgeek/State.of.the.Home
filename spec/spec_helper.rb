require File.join(File.dirname(__FILE__), '../stateofthehome')

gem 'rspec'
require 'rspec'
gem 'rack-test'
require 'rack/test'
require 'date'
require 'json'

set :environment, :test

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/db/test.db")
DataMapper.auto_migrate!

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end


