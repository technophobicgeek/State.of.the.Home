# set up database using datamapper
require 'datamapper'
require 'dm-core'
require 'dm-migrations'
require 'dm-validations'
require 'dm-serializer'
require 'dm-timestamps'


class Household
  include DataMapper::Resource

  property :id,             Serial
  property :name,           String, :required => true
  property :code,           String, :length => 6
  property :created_at,     DateTime
  property :updated_at,     DateTime
  
  has n,  :chores
  has n,  :todos
  has n,  :members
  has n,  :messages
  has n,  :activities
  has n,  :locations

  validates_uniqueness_of :code
  
  before :save,  :set_auto_properties
  
  def self.accept_params(params)
    params.delete("code") # can't update code
    params.delete("name") if params["name"].blank?
    return params    
  end
  
  def set_auto_properties
    self.code ||= $bitly.shorten("http://stateofthehome.heroku.com/api/v1/household/#{self.id}").user_hash
  end
  
end

# Chores have a specific set of states associated
class Chore
  include DataMapper::Resource

  property :id,             Serial
  property :name,           String, :required => true
  property :ordernum,       Integer, :required => true
  property :created_at,     DateTime
  property :updated_at,     DateTime

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
  property :created_at,     DateTime
  property :updated_at,     DateTime
  property :done,           Boolean,  :default => false
  
  belongs_to  :household
  has n,      :tags
end

class Tag
  include DataMapper::Resource

  property :id,             Serial
  property :value,          String,   :required => true
  
  has n,      :todos
end

class TagTodo
  include DataMapper::Resource
  
  belongs_to  :todo,  :key => true
  belongs_to  :tag,   :key => true
end

class Member
  include DataMapper::Resource

  property :id,           Serial
  property :name,         String,  :required => true, :key => true
  property :email,        String
  property :cell,         String
  property :twitter,      String
  
  belongs_to :household,  :key => true
end

class Message
  include DataMapper::Resource

  property :id,             Serial
  property :text,           Text,     :required => true
  property :created_at,     DateTime
  
  belongs_to  :member
  has 1,      :location,  :required => false
end

class Activity
  include DataMapper::Resource

  property :id,             Serial
  property :text,           Text,     :required => true
  property :created_at,     DateTime
  
  belongs_to  :member,    :required => false
  belongs_to  :chore,     :required => false
  belongs_to  :todo,      :required => false
  has 1,      :location,  :required => false
end

class Location
  include DataMapper::Resource

  property :id,           Serial
  property :name,         String,  :required => true, :key => true
  
  belongs_to    :household, :key => true
end

DataMapper.finalize

# Set up database logs
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/db/project.db")
DataMapper::Logger.new($stdout, :debug)
DataMapper.auto_migrate!
