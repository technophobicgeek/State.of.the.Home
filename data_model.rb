# set up database using datamapper

class Household
  include DataMapper::Resource

  # fields
  property :id,             Serial
  property :name,           String
  property :code,           String
  property :last_updated,   Integer
  # validations
  validates_uniqueness_of :code
end

DataMapper.finalize

# Set up database logs
DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/db/project.db")

Household.auto_migrate! unless Household.storage_exists?

