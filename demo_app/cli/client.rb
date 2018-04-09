require 'faye/websocket'
require 'eventmachine'
require 'rest-client'
require 'securerandom'
require 'json'
require 'table_print'
require 'ostruct'

STDOUT.sync = true
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

def get_feed_ids(ids, after_timestamp)
  response = RestClient.get(
    "http://" + URL + "/activity_feeds/subscription?feed_ids=#{ids.join(',')}&since=#{after_timestamp}",
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
    puts ""
    puts "New data for subscription! Processing messages after: #{latest_item}"
    puts ""
    puts "----------------"
    begin
      feeds = []
      if parsed_feed_ids.size == 1
        feeds = get_single_feed(parsed_feed_ids[0], latest_item)

      else
        feeds = get_feed_ids(parsed_feed_ids, latest_item)
      end
      unless feeds.empty?
        feeds = feeds.map do |feed_item| 
          data = feed_item["data"]
          data = data.merge("text" => feed_item["data"]["payload"]["text"])
          OpenStruct.new(data)
        end
        latest_item = feeds[0].created_at
        tp feeds, :id, :feed_id, :text => { width:  140 }
      end
    rescue => e
      puts e
    end
  end

  ws.on :close do |event|
    puts [:close, event.code, event.reason]
    ws = nil
    exit 0
  end
}
