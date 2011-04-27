require 'time'
require 'bitly'
require 'yaml'
require 'data_model'

# Load API info
$apikeys = YAML::load_file("apikeys.yml")

# Bitly
bitly_info = $apikeys["bitly"]
Bitly.use_api_version_3
$bitly = Bitly.new(bitly_info["user"], bitly_info["key"] )

before do
  content_type 'application/json'
end
