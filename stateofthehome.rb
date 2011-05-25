require 'rubygems'
require 'time'
require 'bitly'
require 'simplegeo'
require 'yaml'
require 'sinatra'
require 'haml'
require 'sass'

require File.join(File.dirname(__FILE__), 'data_model')
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

before '/api/*' do
  content_type 'application/json'
end

helpers do
  def find_group
    group = Group.first(:code => params[:code])
    halt error 404, "Group \"#{params[:code]}\" not found" unless group
    group
  end
  def find_group_relation(rel)
    v = rel.first(:id => params[:id], :group => find_group)
    halt error 404, "#{rel.name} #{params[:id]} not found" unless v
    v
  end
  def find_task
    find_group_relation Task
  end
  def find_location
    find_group_relation Location
  end
  def find_member
    find_group_relation Member
  end
  def create_states_for_task(c_params,task)
    c_params["states"].each do |s_params|
      State.create(State.accept_params(s_params,task))     
    end
  end
end

# CSS

get '/application.css' do
  headers 'Content-Type' => 'text/css; charset=utf-8'
  scss :style
end

# Pages

# Get all tasks with no parent tasks
get '/group/:code/tasks' do
  @group = find_group
  @tasks = Task.all(:group => @group, :parent => @group.root_task)
  haml :tasks
end

get '/group/:code/task/:id/children' do
  @parent = find_task 
  @tasks = @parent.children
  
  if @parent.parent
    @back = "/group/#{@parent.group.code}/task/#{@parent.parent.id}/children"
  else
    @back = "/group/#{@parent.group.code}/tasks"
  end
  
  @title = @parent.name
  haml :tasks
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

get '/api/v1/group/:code/location/:id' do
  find_location.to_json
end
get '/api/v1/group/:code/member/:id' do
  find_member.to_json
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


post '/api/v1/group/:code/location/new' do
  begin
    l_params = Location.accept_params(JSON.parse(request.body.read),find_group)
    location = Location.create l_params
    halt error 400, "error creating location".to_json unless location.saved?
    location.to_json
  rescue => e
    error 400, e.message.to_json
  end
end

post '/api/v1/group/:code/member/new' do
  begin
    m_params = Member.accept_params(JSON.parse(request.body.read),find_group)
    member = Member.create m_params
    halt error 400, "error creating member".to_json unless member.saved?
    member.to_json
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


put '/api/v1/group/:code/member/:id' do
  begin
    m_params = Member.accept_params(JSON.parse(request.body.read))
    member = find_member
    member.update m_params
    halt error 400, "error updating member".to_json unless member.saved?
    member.to_json
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


