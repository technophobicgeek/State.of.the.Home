require_relative '../stateofthehome'
gem 'rspec'
require 'rspec'
gem 'rack-test'
require 'rack/test'
require 'date'

set :environment, :test

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end

def app
  Sinatra::Application
end

describe "service" do
  before(:each) do
    Household.destroy
    Chore.destroy
  end
  
  # Household model
  describe "GET on /api/v1/household/:code" do
    before(:each) do
      @household = Household.create(
        :code   => "ABCDEF",
        :name   => "The Tango Loft"
      )
    end
    
    it "should return a household by code" do
      get '/api/v1/household/ABCDEF'
      last_response.should be_ok
      attributes = JSON.parse(last_response.body)
      attributes["code"].should == "ABCDEF"
      attributes["name"].should == "The Tango Loft"
      attributes["created_at"].should_not be_blank      
      attributes["updated_at"].should_not be_blank
    end
    
    it "should return a 404 for a household that doesn't exist" do
      get '/api/v1/household/foo'
      last_response.status.should == 404
    end
    
    describe "GET on /api/v1/household/:code/chore" do      
    end
    
  end

  describe "POST on /api/v1/household" do
    it "should create a household" do
      post '/api/v1/household', {
        :name  => "The Tango Loft"
      }.to_json
      last_response.should be_ok

      attributes = JSON.parse(last_response.body)
      attributes["id"].should_not be_nil
      code = attributes["code"]
      code.length.should == 6

      get "/api/v1/household/#{code}"
      last_response.should be_ok
    end
  end
  
  describe "PUT on /api/v1/household/:code" do
    before(:each) do
      Household.create(
        :code   => "ABCDEF",
        :name   => "The Tango Loft"
      )
    end
    
    it "should update the name of a household" do
      put '/api/v1/household/ABCDEF', {
        :name  => "Our Tango Loft"
      }.to_json
      last_response.should be_ok

      attributes = JSON.parse(last_response.body)
      attributes["name"].should == "Our Tango Loft"
    end
   
    it "should not update the name of a household with a blank name" do
      put '/api/v1/household/ABCDEF', {
        :name  => ""
      }.to_json
      last_response.should be_ok

      attributes = JSON.parse(last_response.body)
      attributes["name"].should == "The Tango Loft"
    end
  
    it "should not update the code of a household" do
      put '/api/v1/household/ABCDEF', {
        :code  => "UVWXYZ"
      }.to_json
      last_response.should be_ok

      attributes = JSON.parse(last_response.body)
      attributes["code"].should == "ABCDEF"
    end
        
  end  
end
