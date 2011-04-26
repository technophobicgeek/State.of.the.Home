# set up database using datamapper

class Household
  include DataMapper::Resource

  # fields
  property :id,             Serial
  property :name,           String, :required => true
  property :code,           String, :key => true, :length => 6
  property :last_updated,   Integer
  
  # associations
  has n, :chores
  has n, :todos
  has n, :members
  has n, :messages
  has n, :activities
end

# Chores have a specific set of states associated
class Chore
  include DataMapper::Resource

  # fields
  property :id,             Serial
  property :name,           String, :required => true
  property :order,          Integer, :required => true
  property :last_updated,   Integer

  # associations
  belongs_to  :household
  has n,      :states,
end

class State
  include DataMapper::Resource

  property :id,             Serial
  property :name,           String, :key => true
end

# Association between household, chores and states
class StateOption
  include DataMapper::Resource
  
  property :order,          Integer, :required => true
  property :selected,       Boolean, :default => false
    
  # associations
  belongs_to :chore
  belongs_to :state
end

# Todos are arbitrary tasks
class Todo
  include DataMapper::Resource

  # fields
  property :id,             Serial
  property :name,           String,   :required => true
  property :order,          Integer,  :required => true
  property :last_updated,   Integer
  property :done,           Boolean,  :default => false
  
  # associations
  belongs_to  :household
end

class Member
  include DataMapper::Resource

  property :id,           Serial
  property :name,         String,  :required => true
  property :email,        String
  property :cell,         String
  property :twitter,      String
  
  # associations
  belongs_to :household
end

# An message is associated with a member
class Message
  include DataMapper::Resource

  property :id,           Serial
  property :text,         Text,     :required => true
  property :ts,           Datetime, :required => true
  
  # associations
  belongs_to :member
end

class Activity
  include DataMapper::Resource

  property :id,           Serial
  property :text,         Text,     :required => true
  property :ts,           Datetime, :required => true
  
  # associations
  belongs_to :member
  belongs_to :chore,  :required => false
  belongs_to :todo,   :required => false
end

DataMapper.finalize

# Set up database logs
DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/db/project.db")

Household.auto_migrate! unless Household.storage_exists?

