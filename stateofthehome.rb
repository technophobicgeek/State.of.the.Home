require 'time'
require 'bitly'
require 'simplegeo'
require 'yaml'
require 'sinatra'

require_relative 'data_model'

configure do
  # Load API info
  $apikeys = YAML::load_file("apikeys.yml")
  
  # Bitly
  bitly_info = $apikeys["bitly"]
  Bitly.use_api_version_3
  $bitly = Bitly.new(bitly_info["user"], bitly_info["key"] )
  
  #SimpleGeo
  simplegeo_info = $apikeys["simplegeo"]
  $simplegeo = SimpleGeo::Client
  $simplegeo.set_credentials(simplegeo_info["token"], simplegeo_info["secret"])
end

configure :development do |config|
  require "sinatra/reloader"
  config.also_reload "data_model.rb"
end

before do
  content_type 'application/json'
end

get '/api/v1/household/:code' do
  household = Household.first(:code => params[:code])
  return error 404, "household not found".to_json unless household
  household.to_json
end

post '/api/v1/household' do
  begin
    body = JSON.parse(request.body.read)
    household = Household.create(body)    
    return error 400, "error creating household".to_json unless household.saved?
    household.to_json
  rescue => e
    error 400, e.message.to_json
  end
end

put '/api/v1/household/:code' do 
  household = Household.first(:code => params[:code])
  return error 404, "household not found".to_json unless household
  begin
    body = Household.accept_params(JSON.parse(request.body.read))
    household.update(body) # TODO if timestamps work
    household.to_json
  rescue => e
    error 400, e.message.to_json
  end
end

#delete '/api/v1/household/:code' do |code|
#  household = Household.first(:code => code)
#  return error 404, "household not found".to_json unless household
#  household.destroy
#  status 200
#  body "Deleted household #{code}"
#end
