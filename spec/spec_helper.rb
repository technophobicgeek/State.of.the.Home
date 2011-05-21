require_relative '../stateofthehome'
gem 'rspec'
require 'rspec'
gem 'rack-test'
require 'rack/test'
require 'date'
require 'json'

set :environment, :test

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end


