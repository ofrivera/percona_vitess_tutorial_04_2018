require 'faye/websocket'
require 'eventmachine'
require 'rest-client'
require 'securerandom'
require 'json'

HOST = ENV['APP_HOST'] || '127.0.0.1'
PORT = ENV['APP_PORT'] || '3000'
URL = "#{HOST}:#{PORT}"
feed_ids = ARGV[0]
parsed_feed_ids = feed_ids.split(',')
latest_item = 0
fail "Invalid feed ids"unless parsed_feed_ids.size > 0


def get_single_feed(id, after_timestamp)
  response = RestClient.get(
    "http://" + URL + "/activity_feeds/#{id}?since=#{after_timestamp}",
    {content_type: :json, accept: :json})
  fail "Couldn't fetch feed #{response}" unless response.code == 200
  JSON.parse(response.body)
end

EM.run {
  ws = Faye::WebSocket::Client.new('ws://' + URL + "/subscribe/activity_feeds?feed_ids=#{feed_ids}")

  ws.on :open do |event|
    puts [:open]
    ws.send('ping')
  end

  ws.on :message do |event|
    puts "Got the following message from web socket: #{event.data}"
    if parsed_feed_ids.size == 1
      begin
      feed = get_single_feed(parsed_feed_ids[0], latest_item)
      latest_item = feed[0]["data"]["created_at"]
      puts feed
      rescue => e
        puts e
      end
    end
  end

  ws.on :close do |event|
    puts [:close, event.code, event.reason]
    ws = nil
    exit 0
  end
}
