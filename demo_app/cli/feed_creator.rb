require 'rest-client'
require 'securerandom'
require 'json'
HOST = ENV['APP_HOST'] || '127.0.0.1'
PORT = ENV['APP_PORT'] || '3000'
URL = "http://#{HOST}:#{PORT}"
ITERATIONS = ENV['NUM_ITERATIONS'] || 1000
SLEEP_TIME = ENV['SLEEP_TIME'] || 1


user = { "data": { "name": "rafael", "email": "rafael+#{SecureRandom.hex}@gmail.com" } }

response = RestClient.post(
  URL + "/users",
  user.to_json,
  {content_type: :json, accept: :json})

raise "Couldn't create user #{response}" unless response.code == 201

user = JSON.parse(response.body)

puts "Created the following user: #{user}"
feed_id = user["data"]["feeds"][0]["data"]["id"]
puts "Going to start posting feed items to user feed id #{feed_id}"
(1..ITERATIONS).each do |i|
  feed_item = {	"data": { "type": "t", "text": "This is a random post: #{SecureRandom.hex}" } }
  response = RestClient.post(
    URL + "/activity_feeds/#{feed_id}",
    feed_item.to_json,
    {content_type: :json, accept: :json})
  fail "Failed to create feed, aborting... " unless response.code == 201
  sleep SLEEP_TIME
  puts "Successfully created activity feed item"
end

puts "Done..."



