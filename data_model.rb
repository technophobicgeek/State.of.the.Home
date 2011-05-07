# set up database using datamapper
require 'rubygems'
require 'datamapper'
require 'dm-core'
require 'dm-migrations'
require 'dm-validations'
require 'dm-serializer'
require 'dm-timestamps'
require 'dm-is-list'
require 'dm-is-tree'
require 'json'

# Interesting ideas to capture
# Log entries on "state transitions"
# Log should be publishable from various points: some design pattern?
# Billing Chore: how do we reset?

class Group
  include DataMapper::Resource

  property :id,             Serial
  property :name,           String, :required => true
  property :code,           String, :length => 6
  property :created_at,     DateTime
  property :updated_at,     DateTime
  
  has n,  :chores
  has n,  :todos
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
  
end

######################### Tasks #########################

module Task
  def self.included(base)
    base.class_eval do      
      include DataMapper::Resource
      
      property :name,           String,   :required => true, :unique => :group_id
      property :created_at,     DateTime
      property :updated_at,     DateTime
    
      belongs_to  :group
      validates_uniqueness_of :name, :scope => :group_id
    end
  end
end

# Chores have a specific set of states associated
class Chore
  include DataMapper::Resource
  include Task

  property :id,             Serial
  property :due_date,       DateTime
  property :reset_date,     DateTime
  
  has n,    :states
  has 1,    :selected, 'State'
  is :list, :scope => :group_id
  

end



# Todos are arbitrary tasks
class Todo
  include DataMapper::Resource
  include Task
  
  property :id,             Serial
  property :due_date,       Date
  property :priority,       Integer,  :default => 0
  property :done_date,      Date
  
  is :tree, :order => priority
end

class State
  include DataMapper::Resource

  property :id,             Serial
  property :name,           String,   :key => true
  
  belongs_to :chore
  is  :list,  :scope => :chore_id

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
  belongs_to  :chore,       :required => false
  belongs_to  :todo,        :required => false
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
