require File.dirname(__FILE__) + '/../stateofthehome'
gem 'rspec'
require 'rspec'
gem 'rack-test'
require 'rack/test'
require 'date'

set :environment, :test
#Test::Unit::TestCase.send :include, Rack::Test::Methods

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end

def app
  Sinatra::Application
end

describe "service" do
  before(:each) do
    Household.destroy
  end

  describe "GET on /api/v1/household/:code" do
    before(:each) do
      Household.create(
        :code   => "ABCDEF",
        :name   => "Apna Household",
        :last_updated => Time.now
      )
    end

    it "should return a dishwasher by code" do
      get '/api/v1/household/ABCDEF'
      last_response.should be_ok
      attributes = JSON.parse(last_response.body)
      attributes["code"].should == "ABCDEF"
    end

    it "should return a dishwasher with a status" do
      get '/api/v1/household/ABCDEF'
      last_response.should be_ok
      attributes = JSON.parse(last_response.body)
      last_updated = attributes["last_updated"]
      last_updated.should_not be_blank
    end


    it "should return a 404 for a dishwasher that doesn't exist" do
      get '/api/v1/household/foo'
      last_response.status.should == 404
    end
  end

  describe "POST on /api/v1/household" do
    it "should create a dishwasher" do
      post '/api/v1/household', {
        :name  => "Apna Household"
      }.to_json
      last_response.should be_ok

      # On creating a dishwasher, return a random code
      attributes = JSON.parse(last_response.body)
      attributes["id"].should_not be_nil
      code = attributes["code"]

      # TODO code should be 6 characters long
      code.length.should == 6

      get "/api/v1/household/#{code}"
      attributes = JSON.parse(last_response.body)
      attributes["code"].should  == "#{code}"
      attributes["name"].should == "Apna Household"
      attributes["last_updated"].should_not be_blank
    end
  end

  describe "POST on /api/v1/household/update/:code" do
    before :each do
      Household.create(
        :code => "XYZABC",
        :name => "Apna Household",
        :status => "dirty",
        :last_updated => 10000
      )
    end

    it "should return updated info from server if client info is outdated" do
      post '/api/v1/household/update/XYZABC', {
        :status => "clean",:last_updated => "2000"}.to_json
      last_response.should be_ok
      get '/api/v1/household/XYZABC'
      attributes = JSON.parse(last_response.body)
      attributes["code"].should == "XYZABC"
      attributes["last_updated"].should == 10000
    end

    it "should not return new info from server if client info is newer" do
      post '/api/v1/household/update/XYZABC', {
        :status => "clean",:last_updated => "20000"}.to_json
      last_response.should be_ok
      get '/api/v1/household/XYZABC'
      attributes = JSON.parse(last_response.body)
      attributes["code"].should == "XYZABC"
      attributes["name"].should == "Apna Household"
      attributes["last_updated"].should == 20000
    end

    it "should not update a dishwasher using POST with a nil name" do
      post '/api/v1/household/update/XYZABC', {
        :status => "clean", :name => "",:last_updated => "20000"}.to_json
      last_response.should be_ok
      get '/api/v1/household/XYZABC'
      attributes = JSON.parse(last_response.body)
      attributes["code"].should == "XYZABC"
      attributes["name"].should == "Apna Household"
      attributes["last_updated"].should == 20000
    end

    it "should update a dishwasher using POST with a name" do
      post '/api/v1/household/update/XYZABC', {
        :status => "clean", :name => "Hamara Household",:last_updated => "20000"}.to_json
      last_response.should be_ok
      get '/api/v1/household/XYZABC'
      attributes = JSON.parse(last_response.body)
      attributes["code"].should == "XYZABC"
      attributes["name"].should == "Hamara Household"
      attributes["last_updated"].should == 20000
    end
  end

  describe "DELETE on /api/v1/household/:code" do
    it "should delete a dishwasher on DELETE" do
      Household.create(
        :code => "ABCDEF",
        :name => "Apna Household",
        :status => "dirty"
      )
      delete '/api/v1/household/ABCDEF'
      last_response.should be_ok
      get '/api/v1/household/ABCDEF'
      last_response.status.should == 404
    end
  end

  describe "POST on /api/v1/household/delete/:code" do
    it "should delete a dishwasher on POST" do
      Household.create(
        :code => "ABCDEF",
        :name => "Apna Household",
        :status => "dirty"
      )
      post '/api/v1/household/delete/ABCDEF'
      last_response.should be_ok
      get '/api/v1/household/ABCDEF'
      last_response.status.should == 404
    end
  end


end
