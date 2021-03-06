# set up database using datamapper
require 'rubygems'
require 'datamapper'
require 'dm-core'
require 'dm-migrations'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-is-tree'
require 'json'


module JSONHelper
  def to_collection(deep)
    params = self.attributes.delete_if{|k,v| v.nil?}
    params = self.serialize_associations(params,deep) if deep
    params
  end

  def associations
    []
  end
  
  # Instead of passing deep around, could we use t.instance_eval(@deep = true)?
  def serialize_associations(params,deep)
    self.associations.each do |assoc|
      values = self.send(assoc)
      values = values.map{|t| t.to_collection(deep)} if values
      params[assoc] = values unless (values.nil? || values.empty?)
    end
    params
  end
  
  def to_json(options = {})
    deep = options[:deep]
    deep = true if deep.nil?
    self.to_collection(deep).to_json
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
  has 1,  :root_task, 'Task'
  has n,  :members
  has n,  :activity_entries
  has n,  :messages
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
    self.root_task = Task.create(:name => "Tasks" )
  end
  
  def associations
    [:tasks,:members,:locations]
  end
   
end

######################### Tasks #########################


# Tasks have a location, timing, periodicity and a set of states, all of which
# are optional. they also have parent and children tasks

class Task

  class Dependency
    include DataMapper::Resource
  
    storage_names[:default] = 'task_dependencies'
    
    belongs_to :blockedby, 'Task', :key => true
    belongs_to :blockerof, 'Task', :key => true
  end


  include DataMapper::Resource
  include JSONHelper

  property :id,             Serial
  property :name,           String,   :required => true, :unique => :group_id
  property :position,       Integer
  property :task_type,      String
  
  property :created_at,     DateTime
  property :updated_at,     DateTime
  
  property :done,           Boolean,  :default => false  
  property :priority,       Integer,  :default => 0
  
  property :selected,       Integer,  :default => 1
  has n,   :states

  has 1,   :timing
  has 1,   :periodicity
  has 1,   :location
  
  belongs_to  :group
  #validates_uniqueness_of :name, :scope => :group_id

  # Subtasks and supertasks
  is :tree, :order => priority
  
  # Dependency graph: can we enforce the following rules? 
  # 1) Only tasks which are siblings can have dependencies
  # 2) No cycles
  has n, :dep_blockedby_tasks, 'Task::Dependency', :child_key => [:blockerof_id]
  has n, :dep_blockerof_tasks, 'Task::Dependency', :child_key => [:blockedby_id]

  has n, :blockedby_tasks, self,
    :through => :dep_blockedby_tasks,
    :via     => :blockedby

  has n, :blockerof_tasks, self,
    :through => :dep_blockerof_tasks,
    :via     => :blockerof


  def self.accept_params(params,group = nil)
    halt error 400, "Task name cannot be empty" if params["name"].blank?
    params["group"] = group if group
    return params    
  end

  def associations
    [:states,:timing,:periodicity,:location]
  end
  
  def leaf?
    c = self.children
    c.nil? || c.empty?
  end
    
  def selected_state
    self.states.all(:position => self.selected)[0] unless self.states.empty?
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

class Timing
  include DataMapper::Resource
  include JSONHelper

  property :id,             Serial

  property :due_date,       DateTime
  property :reset_date,     DateTime
  property :done_date,      DateTime

  belongs_to  :task 
end

class Periodicity
  include DataMapper::Resource
  include JSONHelper

  property :id,             Serial

  property :freq_key,       String # "daily", "weekly", "monthly"
  property :freq_val,       Integer

  belongs_to  :task 
end

######################### Users #########################

class Member
  include DataMapper::Resource
  include JSONHelper

  property :id,           Serial
  property :name,         String,  :required => true, :unique => :group_id
  property :email,        String
  property :cell,         String
  property :twitter,      String
  
  belongs_to :group
  validates_uniqueness_of :name, :scope => :group_id

  def self.accept_params(params,group = nil)
    %w[name].each do |v|
      halt error 400, "#{self.class} #{v} cannot be empty"  if params[v].blank?
    end
    params["group"] = group if group
    return params    
  end

end

######################### Messages ########################

class Message
  include DataMapper::Resource
  include JSONHelper
  
  property :id,         Serial
  property :text,       Text,     :required => true
  property :created_at, DateTime

  belongs_to  :member
  belongs_to  :group
end


######################### Activities #######################

class ActivityEntry
  include DataMapper::Resource
  include JSONHelper
  
  property :id,    Serial
  property :text,  Text,    :required => false
  property :created_at,      DateTime

  belongs_to  :member,      :required => false
  belongs_to  :task,        :required => false
  belongs_to  :location,    :required => false
  belongs_to  :group
end


######################### Locations ########################

class Location
  include DataMapper::Resource
  include JSONHelper

  property :id,           Serial
  property :name,         String
  property :latitude,     Float,  :required => true
  property :longitude,    Float,  :required => true
  
  belongs_to    :group
  belongs_to    :task,    :required => false

  def self.accept_params(params,group = nil)
    %w[name latitude longitude].each do |v|
      halt error 400, "Location #{v} cannot be empty"  if params[v].blank?
    end
    params["group"] = group if group
    return params    
  end
  
end

############################################################

DataMapper.finalize

# Set up database logs
#DataMapper::Logger.new($stdout, :debug)
#DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/db/project.db")
#DataMapper.auto_migrate!

def create_sample_data
  
  group = Group.create(:code   => "ABCDEF",:name   => "The Tango Loft")
  root = group.root_task
  
  task_p = Task.create(:name => "Kill Bill", :group => group, :position => 3, :priority => 3, :parent => root  )  
  
  task_p = Task.create(:name => "AJ", :group => group, :position => 3, :priority => 3, :parent => root  )  
  
  task = Task.create(:name => "Slingbox", :group => group, :position => 1, :priority => 3, :parent => task_p)  
  task = Task.create(:name => "Cell booster", :group => group, :position => 2, :priority => 3, :parent => task_p )  
  task = Task.create(:name => "Discuss expense app", :group => group, :position => 3, :priority => 3, :parent => task_p )  
  
  
  task = Task.create(:name => "Laundry", :group => group, :position => 4, :parent => task_p  )
  %w[Fresh Stinky].each_with_index {|s,i| State.create(:name => s, :task=> task,:position => i+1)}
  task.update(:selected => 2)
  
  
  task_p = Task.create(:name => "AJ", :group => group, :position => 3, :priority => 3, :parent => root  )  
  
  task = Task.create(:name => "Slingbox", :group => group, :position => 1, :priority => 3, :parent => task_p)  
  task = Task.create(:name => "Cell booster", :group => group, :position => 2, :priority => 3, :parent => task_p )  
  task = Task.create(:name => "Discuss expense app", :group => group, :position => 3, :priority => 3, :parent => task_p )  
  
  
  task_p = Task.create(:name => "Out", :group => group, :position => 3, :priority => 3, :parent => root  )  
  
  task = Task.create(:name => "Medicine", :group => group, :position => 1, :priority => 3, :parent => task_p)  
  task = Task.create(:name => "Mail Netflix", :group => group, :position => 2, :priority => 3, :parent => task_p )  
  task_p = Task.create(:name => "Bank", :group => group, :position => 3, :priority => 3, :parent => task_p )  
  
  task = Task.create(:name => "deposit", :group => group, :position => 1, :priority => 3, :parent => task_p)  
  task = Task.create(:name => "temp card", :group => group, :position => 2, :priority => 3, :parent => task_p )  
  task = Task.create(:name => "get accts", :group => group, :position => 2, :priority => 3, :parent => task_p )  
  
  task_p = Task.create(:name => "Misc", :group => group, :position => 3, :priority => 3, :parent => root  )  
  
  task = Task.create(:name => "Paint doorbell", :group => group, :position => 1, :priority => 3, :parent => task_p)  
  task = Task.create(:name => "test blender", :group => group, :position => 2, :priority => 3, :parent => task_p )  
  task = Task.create(:name => "drawer bottom", :group => group, :position => 2, :priority => 3, :parent => task_p )  
  
  task_p = Task.create(:name => "Misc LGF", :group => group, :position => 3, :priority => 3, :parent => root  )  
  
  task = Task.create(:name => "search popup", :group => group, :position => 1, :priority => 3, :parent => task_p)  
  task = Task.create(:name => "search pane scrolling", :group => group, :position => 2, :priority => 3, :parent => task_p )  
  task = Task.create(:name => "popup size #525", :group => group, :position => 2, :priority => 3, :parent => task_p )  
  
  
  task_p = Task.create(:name => "Chores", :group => group, :position => 3, :priority => 3, :parent => root  )
  
  task = Task.create(:name => "Dishwasher", :group => group, :position => 1, :parent => task_p )
  %w[Clean Dirty].each_with_index {|s,i| State.create(:name => s, :task=> task,:position => i+1)}
  task.update(:selected => 1)
  
  task_p = Task.create(:name => "Make tea", :group => group, :position => 3, :priority => 3, :parent => task_p  )  
  
  task = Task.create(:name => "Get milk", :group => group, :position => 1, :priority => 3, :parent => task_p)  
  task = Task.create(:name => "Boil water", :group => group, :position => 2, :priority => 3, :parent => task_p )  

end