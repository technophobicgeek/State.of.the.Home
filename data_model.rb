# set up database using datamapper
require 'datamapper'
require 'dm-core'
require 'dm-migrations'
require 'dm-validations'
require 'dm-serializer'

class Household
  include DataMapper::Resource

  property :id,             Serial
  property :name,           String, :required => true
  property :code,           String, :key => true, :length => 6
  property :last_updated,   DateTime
  
  has n, :chores
  has n, :todos
  has n, :members
  has n, :messages
  has n, :activities
  has n, :locations
end

# Chores have a specific set of states associated
class Chore
  include DataMapper::Resource

  property :id,             Serial
  property :name,           String, :required => true
  property :ordernum,       Integer, :required => true
  property :last_updated,   DateTime

  belongs_to  :household
  has n,      :states
end

class State
  include DataMapper::Resource

  property :id,             Serial
  property :name,           String, :key => true
  
  has n,      :chores
end

# Association between chores and states
class ChoreState
  include DataMapper::Resource
  
  property  :ordernum,       Integer, :required => true
  property  :selected,       Boolean, :default => false
    
  belongs_to :chore,  :key => true
  belongs_to :state,  :key => true
end

# Todos are arbitrary tasks
class Todo
  include DataMapper::Resource

  property :id,             Serial
  property :name,           String,   :required => true
  property :ordernum,       Integer,  :required => true
  property :last_updated,   DateTime
  property :done,           Boolean,  :default => false
  
  belongs_to  :household
end

class Member
  include DataMapper::Resource

  property :id,           Serial
  property :name,         String,  :required => true
  property :email,        String
  property :cell,         String
  property :twitter,      String
  
  belongs_to :household
end

class Message
  include DataMapper::Resource

  property :id,           Serial
  property :text,         Text,     :required => true
  property :ts,           DateTime, :required => true
  
  belongs_to  :member
  has 1,      :location,  :required => false
end

class Activity
  include DataMapper::Resource

  property :id,           Serial
  property :text,         Text,     :required => true
  property :ts,           DateTime, :required => true
  
  belongs_to  :member
  belongs_to  :chore,     :required => false
  belongs_to  :todo,      :required => false
  has 1,      :location,  :required => false
end

class Location
  include DataMapper::Resource

  property :id,           Serial
  property :name,         String,  :required => true
  
  belongs_to    :household
end

DataMapper.finalize

# Set up database logs
DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/db/project.db")

DataMapper.auto_upgrade!

