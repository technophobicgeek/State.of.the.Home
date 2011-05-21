# set up database using datamapper
require 'rubygems'
require 'datamapper'
require 'dm-core'
require 'dm-migrations'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-is-list'
require 'dm-is-tree'
require 'json'

module JSONHelper
  def to_collection
    params = self.attributes.delete_if{|k,v| v.nil?}
    return self.collect_associations(params)
  end

  def collect_associations(params)
    params
  end
  
  def to_json
    self.to_collection.to_json
  end 
end

# Interesting ideas to capture
# Log entries on "state transitions"
# Log should be publishable from various points: some design pattern?
# Billing Task: how do we reset?

class Group
  include DataMapper::Resource
  include JSONHelper

  property :id,             Serial
  property :name,           String, :required => true
  property :code,           String, :length => 6
  property :created_at,     DateTime
  property :updated_at,     DateTime
  
  has n,  :tasks
  has n,  :members
  has 1,  :activity_log
  has 1,  :message_board
  has n,  :locations

  validates_uniqueness_of :code
  
  before :save,  :set_auto_properties
  
  def self.accept_params(params)
    params.delete("code") # can't update code
    params.delete("name") if params["name"].blank?
    return params    
  end
  
  def set_auto_properties
    self.code ||= $bitly.shorten("http://stateofthehome.heroku.com/api/v1/group/#{self.id}").user_hash
  end
  
  def collect_associations(params)
    tasks = self.tasks.map{|t| t.to_collection}
    params[:tasks] = tasks unless tasks == []
    return params
  end

end

######################### Tasks #########################


# Tasks have a specific set of states associated
class Task
  include DataMapper::Resource
  include JSONHelper

  property :id,             Serial
  property :name,           String,   :required => true, :unique => :group_id
  property :position,       Integer
  property :ttype,          String
  
  property :created_at,     DateTime
  property :updated_at,     DateTime
  
  property :due_date,       DateTime
  property :reset_date,     DateTime

  property :done_date,      DateTime
  property :done,           Boolean,  :default => false  
  property :priority,       Integer,  :default => 0
  
  property :selected,       Integer,  :default => 1
  has n,   :states


  belongs_to  :group
  validates_uniqueness_of :name, :scope => :group_id

  is :tree, :order => priority
  

  def self.accept_params(params,group = nil)
    halt error 400, "Task name cannot be empty" if params["name"].blank?
    params["group"] = group if group
    return params    
  end

  def collect_associations(params)
    states = self.states.map{|t| t.to_collection}
    params[:states] = states unless states == []
    return params
  end
    
end

class State
  include DataMapper::Resource
  include JSONHelper

  property :id,             Serial
  property :name,           String,   :key => true
  property :position,       Integer
  
  belongs_to  :task

  def self.accept_params(params,task)
    halt error 400, "State name cannot be empty"  if params["name"].blank?
    params["task"] = task
    return params    
  end
  
end



######################### Users #########################

class Member
  include DataMapper::Resource

  property :id,           Serial
  property :name,         String,  :required => true, :unique => :group_id
  property :email,        String
  property :cell,         String
  property :twitter,      String
  
  belongs_to :group
  validates_uniqueness_of :name, :scope => :group_id
end

######################### Messages ########################

class Message
  include DataMapper::Resource
  
  property :id,         Serial
  property :text,       Text,     :required => true
  property :created_at, DateTime

  belongs_to  :member
  belongs_to  :message_board
end

class MessageBoard
  include DataMapper::Resource
  
  property :id,  Serial

  belongs_to :group
  has n,     :messages
end

######################### Activities #######################

class ActivityEntry
  include DataMapper::Resource
  
  property :id,    Serial
  property :text,  Text,    :required => false
  property :created_at,      DateTime

  belongs_to  :member,      :required => false
  belongs_to  :task,       :required => false
  belongs_to  :location,    :required => false
  belongs_to  :activity_log
end

class ActivityLog
  include DataMapper::Resource

  property :id,             Serial
  
  belongs_to  :group
  has n,      :activity_entries
end

######################### Locations ########################

class Location
  include DataMapper::Resource

  property :id,           Serial
  property :name,         String,  :required => true, :key => true
  
  belongs_to    :group,   :key => true
end

############################################################

DataMapper.finalize

# Set up database logs
#DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/db/project.db")
DataMapper.auto_migrate!
