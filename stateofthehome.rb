#require 'rubygems'
#require 'bundler/setup'
require 'time'

require 'datamapper'
require 'dm-core'
require 'dm-migrations'
require 'dm-validations'
require 'dm-serializer'

require 'sinatra'
require 'bitly'

require 'data_model'


Bitly.use_api_version_3
$bitly = Bitly.new("plusbzz", "R_18b965b49460efd206c595f066f43370")



before do
  content_type 'application/json'
end

# the HTTP entry points to our service

get '/api/v1/household/:code' do
  household = Household.first(:code => params[:code])
  if household
    household.to_json
  else
    error 404, "household not found".to_json
  end
end

post '/api/v1/household' do
  begin
    body = JSON.parse(request.body.read)
    household = Household.create(body)

    if household
      u = $bitly.shorten("http://stateofthehome.heroku.com/api/v1/households/#{household.id}")

      household.code = u.user_hash
      household.last_updated ||= Time.now.utc.to_i
      household.save
      household.to_json
    else
      error 400, "error creating household".to_json
    end

  rescue => e
    error 400, e.message.to_json
  end
end


post '/api/v1/households/update/:code' do
  update_household(params[:code])
end

delete '/api/v1/households/:code' do
  delete_household(params[:code])
end

post '/api/v1/households/delete/:code' do
  delete_household(params[:code])
end

private

  # TODO validate updates
  #     cannot update code
  #     status should be clean or dirty
  #     name should be bounded

  def update_household(code)
    household = Household.first(:code => code)
    if household
      begin
        body = JSON.parse(request.body.read)
        puts body
        client_ts = preprocess_update_request(body)
        server_ts = household.last_updated
        household.update(body) if client_ts > server_ts # client's info is newer
        puts household.to_json
        household.to_json
      rescue => e
        error 400, e.message.to_json
      end
    else
      error 404, "household not found".to_json
    end
  end

  # Return the last_updated field from the http request.
  def preprocess_update_request(body)
    body.delete("code") # can't update code
    body.delete("name") if body["name"].blank?
    body.delete("status") if body["status"].blank?
    client_last_update = body["last_updated"]
    ts = (client_last_update.blank? ? 0 : client_last_update)
    ts.to_i
  end

  def delete_household(code)
    household = Household.first(:code => code)
    if household
      household.destroy
      household.to_json
    else
      error 404, "household not found".to_json
    end
  end
