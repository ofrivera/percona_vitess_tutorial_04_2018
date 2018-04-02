require 'logger'
require 'sinatra/base'
require 'sinatra/json'
require 'active_support/core_ext/hash/indifferent_access'
require 'bundler'
Bundler.require


require_relative_directory 'lib'
require_relative_directory 'app'

class App < Sinatra::Base
  configure :production, :development do
    enable :logging
  end

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

  get '/activity_feeds/:feed_id' do |feed_id|
    @feed_items = FeedItem.find_by_feed_id(
      feed_id: feed_id,
      since: params[:since],
    )
    json @feed_items.map(&:to_json)
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
    status 201
  end
end
