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
end
