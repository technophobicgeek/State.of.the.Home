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

get '/api/v1/group/:code' do
  group = Group.first(:code => params[:code])
  return error 404, "group not found".to_json unless group
  group.to_json
end

post '/api/v1/group' do
  begin
    body = JSON.parse(request.body.read)
    group = Group.create(body)    
    return error 400, "error creating group".to_json unless group.saved?
    group.to_json
  rescue => e
    error 400, e.message.to_json
  end
end

put '/api/v1/group/:code' do 
  group = Group.first(:code => params[:code])
  return error 404, "group not found".to_json unless group
  begin
    body = Group.accept_params(JSON.parse(request.body.read))
    group.update(body) # TODO if timestamps work
    group.to_json
  rescue => e
    error 400, e.message.to_json
  end
end

#Delete a group only if the number of members drops to 0?
#delete '/api/v1/group/:code' do |code|
#  group = Group.first(:code => code)
#  return error 404, "group not found".to_json unless group
#  group.destroy
#  status 200
#  body "Deleted group #{code}"
#end
