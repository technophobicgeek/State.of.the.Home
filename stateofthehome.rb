require 'rubygems'
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
  def find_chore
    chore = Chore.first(:id => params[:id], :group => find_group)
    halt error 404, "Chore \"#{params[:id]}\" not found" unless chore
    chore
  end
  def create_states_for_chore(c_params,chore)
    c_params["states"].each do |s_params|
      State.create(State.accept_params(s_params,chore))     
    end
  end
end

# All GET requests
get '/api/v1/group/:code' do
  find_group.to_json
end

get '/api/v1/group/:code/chores/all' do
  find_group.to_json(
    :only => [:name,:code],
    :relationships => {
      :chores => {
        :only => [:id,:name,:position,:selected],
        :relationships => {
          :states   => { :only => [:name,:position]},
        }
      }
    }
  )
end

get '/api/v1/group/:code/chores/selected' do
  find_group.to_json(
    :only => [:code],
    :relationships => {
      :chores => {
        :only => [:id,:selected]
      }
    }
  )
end

get '/api/v1/group/:code/chore/:id' do
  find_chore.to_json_basic
end

get '/api/v1/group/:code/chore/:id/selected' do
  find_chore.to_json(:only => [:selected])
end

# All POST requests
post '/api/v1/group/new' do
  begin
    body = JSON.parse(request.body.read)
    group = Group.create(body)    
    halt error 400, "error creating group".to_json unless group.saved?
    group.to_json
  rescue => e
    error 400, e.message.to_json
  end
end

post '/api/v1/group/:code/chore/new' do
  begin
    c_params = Chore.accept_params(JSON.parse(request.body.read),find_group)
    chore = Chore.create c_params
    create_states_for_chore(c_params,chore)
    halt error 400, "error creating chore".to_json unless chore.saved?
    chore.to_json_basic
  rescue => e
    error 400, e.message.to_json
  end
end

# All PUT requests
put '/api/v1/group/:code' do 
  group = find_group
  begin
    body = Group.accept_params(JSON.parse(request.body.read))
    group.update body # TODO if timestamps work
    group.to_json
  rescue => e
    error 400, e.message.to_json
  end
end

put '/api/v1/group/:code/chore/:id' do
  begin
    c_params = Chore.accept_params(JSON.parse(request.body.read))
    chore = find_chore
    #chore.update c_params
    halt error 400, "error updating chore".to_json unless chore.saved?
    chore.to_json_basic
  rescue => e
    error 400, e.message.to_json
  end
end
#
#put '/api/v1/group/:code/chore/:id/selected' do
#  begin
#    group = Group.first(:code => params[:code])
#    return error 404, "group not found".to_json unless group
#    body = JSON.parse(request.body.read)
#  rescue => e
#    error 400, e.message.to_json
#  end
#end


# All DELETE requests
#Delete a group only if the number of members drops to 0?
#delete '/api/v1/group/:code' do |code|
#  group = Group.first(:code => code)
#  return error 404, "group not found".to_json unless group
#  group.destroy
#  status 200
#  body "Deleted group #{code}"
#end
