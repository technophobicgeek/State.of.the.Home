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

helpers do
  def find_group
    group = Group.first(:code => params[:code])
    halt error 404, "Group \"#{params[:code]}\" not found" unless group
    group
  end
end

# All GET requests
get '/api/v1/group/:code' do
  find_group.to_json
end

get '/api/v1/group/:code/chores/all' do
  group = find_group
end

get '/api/v1/group/:code/chores/selected' do
end

get '/api/v1/group/:code/chore/:name' do
end

# All POST requests
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

post '/api/v1/group/:code/chore' do
  begin
    group = Group.first(:code => params[:code])
    return error 404, "group not found".to_json unless group
    body = JSON.parse(request.body.read)
  rescue => e
    error 400, e.message.to_json
  end
end

# All PUT requests
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

put '/api/v1/group/:code/chore/:id/selected' do
  begin
    group = Group.first(:code => params[:code])
    return error 404, "group not found".to_json unless group
    body = JSON.parse(request.body.read)
  rescue => e
    error 400, e.message.to_json
  end
end


# All DELETE requests
#Delete a group only if the number of members drops to 0?
#delete '/api/v1/group/:code' do |code|
#  group = Group.first(:code => code)
#  return error 404, "group not found".to_json unless group
#  group.destroy
#  status 200
#  body "Deleted group #{code}"
#end
