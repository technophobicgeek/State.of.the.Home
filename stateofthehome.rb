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
  def find_task
    task = Task.first(:id => params[:id], :group => find_group)
    halt error 404, "Task #{params[:id]} not found" unless task
    task
  end
  def create_states_for_task(c_params,task)
    c_params["states"].each do |s_params|
      State.create(State.accept_params(s_params,task))     
    end
  end
end

# All GET requests
get '/api/v1/group/:code/all' do
  find_group.to_json
end

get '/api/v1/group/:code' do
  find_group.to_json(:deep => false)
end

get '/api/v1/group/:code/task/:id' do
  find_task.to_json
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

post '/api/v1/group/:code/task/new' do
  begin
    c_params = Task.accept_params(JSON.parse(request.body.read),find_group)
    task = Task.create c_params
    create_states_for_task(c_params,task)
    halt error 400, "error creating task".to_json unless task.saved?
    task.to_json
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

put '/api/v1/group/:code/task/:id' do
  begin
    c_params = Task.accept_params(JSON.parse(request.body.read))
    task = find_task
    task.update c_params
    halt error 400, "error updating task".to_json unless task.saved?
    task.to_json
  rescue => e
    error 400, e.message.to_json
  end
end

delete '/api/v1/group/:code/task/:id' do
  begin
    task = find_task
    task.states.map {|s| s.destroy!}
    res = task.destroy!
    "Task #{task.name} destroyed" if res
    halt error 400, "error destroying task".to_json unless res
  rescue => e
    error 400, e.message.to_json
  end
end


