require './stateofthehome'

configure :production, :development do |config|
    DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/db/project.db")
    DataMapper.auto_migrate!
end


configure :development do |config|
  require "sinatra/reloader"
  config.also_reload "data_model.rb"
  create_sample_data
end

run Sinatra::Application
