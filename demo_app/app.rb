require 'logger'
require 'sinatra/base'
require 'sinatra/json'
require 'active_support/core_ext/hash/indifferent_access'
require 'sinatra-websocket'
require 'bundler'
Bundler.require


require_relative_directory 'lib'
require_relative_directory 'app'

class App < Sinatra::Base
  configure :production, :development do
    enable :logging
  end

  set :sockets, {}


  get '/' do
    json "ok": 200
  end

  post '/users' do
    payload = JSON.parse(request.body.read)
    unless payload
      response = { code: 1, status: '422', title: "invalid user"}
      halt 422, json(response)
      return
    end
    begin
      json_user = ActiveSupport::HashWithIndifferentAccess.new(payload["data"])
      @user = User.new(json_user)
      @user.save!
      @user.create_feed("main")
      logger.info("Created user: #{@user.to_json}")
      status 201
      json @user.to_json
    rescue => e
      response = { code: 2, status: '422', title: e.message}
      logger.error(e)
      halt 422, json(response)
    end
  end

  get '/activity_feeds/subscription' do
    feed_ids = params[:feed_ids].split(',')
    if feed_ids.empty?
      response = { code: 1, status: '422', title: "invalid subscription ids"}
      halt 422, json(response)
    end
    @feed_items = FeedItem.find_by_feed_ids(
      since: params[:since],
      feed_ids: feed_ids
    )
    json @feed_items.map(&:to_json)
  end

  get '/activity_feeds/:feed_id' do |feed_id|
    @feed_items = FeedItem.find_by_feed_id(
      feed_id: feed_id,
      since: params[:since],
    )
    json @feed_items.map(&:to_json)
  end

  get '/subscribe/activity_feeds' do
    if !request.websocket?
      response = { code: 1, status: '422', title: "This endpoint should be used with websocket connections"}
      halt 422, json(response)
    else
      request.websocket do |ws|
        feed_ids = params['feed_ids'].split(',')
        if feed_ids.empty?
          response = { code: 1, status: '422', title: "Invalid feed ids provided"}
          halt 422, json(response)
        end

        ws.onmessage do |msg|
          logger.info("Got message #{msg}")
          #EM.next_tick { settings.sockets.each{|s| s.send(msg) } }
        end
        ws.onopen do
          logger.info("Opened a new websocket for: #{feed_ids}")
          ws.send("Successfully subscribed to socket for feeds: ")
          feed_ids.each do |feed_id|
            settings.sockets[feed_id] = [] unless settings.sockets[feed_id]
            settings.sockets[feed_id] << ws
          end
        end

        ws.onclose do
          logger.info("websocket closed")
          settings.sockets.values.each do |sockets|
            sockets.delete(ws)
          end
          logger.info("Active connections count: #{settings.sockets.values.flatten.count}")
        end
      end
    end
  end

  post '/activity_feeds/:feed_id' do |feed_id|
    @feed = Feed.find_by_id(feed_id)
    response = { code: 4, status: '404', title: 'feed not found' }
    halt 404, json(response) unless @feed
    payload = JSON.parse(request.body.read)
    json_feed_item = ActiveSupport::HashWithIndifferentAccess.new(payload["data"])
    response = { code: 2, status: '422', title: 'feed not found' }
    halt 422, json(response) unless  json_feed_item
    halt 422, json(response) unless  FeedItemTypes.valid?(json_feed_item['type'])
    @feed.add_text_item(json_feed_item[:text])
    if settings.sockets[feed_id]
      msg = {data: { type: 'feed_updated', feed_id: feed_id}}.to_json
      EM.next_tick { settings.sockets[feed_id].each{|s| s.send(msg) } }
    end
    status 201
  end
end
