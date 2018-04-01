require 'logger'
require 'sinatra/base'
require 'mysql2'
require 'mysql2-cs-bind'

class App < Sinatra::Base

  get '/' do
    'Hello world!'
  end

  post '/users' do
    @user = User.new('rafael', '1', 'rafael@slack-corp.com')
    $dao.insert_user(@user)
  end
end

class DbClient
  attr_accessor :client

  @@user_ids = ($db_client.xquery("select id from users order by ASC limit 1").first || 0) + 1
  @@feed_ids = ($db_client.xquery("select id from feeds order by ASC limit 1").first || 0) + 1
  @@feed_item_ids = ($db_client.xquery("select id from feed_items order by ASC limit 1").first || 0) + 1

  INSERT_USER='INSERT INTO users (id, name, email) VALUES(?, ?, ?)'
  INSERT_FEED='INSERT INTO feeds (id, user_id, description, created_at, updated_at) VALUES (? , ?, ?, ?, ?)'
  INSERT_FEED_ITEM='INSERT INTO feed_items (id, feed_id, feed_type, created_at, payload) VALUES (?, ?, ?, ?, ?)'
  SELECT_USER_FEEDS='SELECT * from feed_items where feed_id = ? LIMIT ?'
  SELECT_SUBSCRIBED_FEEDS='SELECT * from feed_items where feed_id IN (?) LIMIT ?'

  def initialize(user, password, host, port, database)
    @client = Mysql2::Client.new(
      adapter: 'mysql2',
      username: user,
      password: password,
      host: host,
      port: port,
      database: database
    )
  end

  def insert_user(user)
    @client.xquery(INSERT_USER, @@user_ids, user.name, user.email)
    @@user_ids += 1
    return true
  end

  def insert_user(user)
    @client.xquery(INSERT_USER, @@user_ids, user.name, user.email)
    @@user_ids += 1
    return true
  end

  def insert_feed(feed)
    @client.xquery(
      INSERT_FEED,
      @@feed_ids,
      feed.user_id,
      feed.description,
      feed.created_at,
      feed.updated_at
    )
    @@feed_ids += 1
    return true
  end

  def insert_feed_item(feed_item)
    @client.xquery(
      INSERT_FEED,
      @@feed_item_ids,
      feed_item.feed_id,
      feed_item.feed_type,
      feed_item.created_at,
      feed_item.payload
    )
    @@feed_ids += 1
    return true
  end
end

$db_client = DbClient.new('mysql_user', 'mysql_password', 'macondo', '15306', 'test_keyspace')

class User

  @@db_client = $db_client

  attr_accessor :id, :name, :email

  def initialize(name, email)
    @name  = name
    @email = email
  end

  def save!
    return true if self.id != nil
    self.id = @@id
    @@db_client.insert_user(self)
    return true
  end
end

class Feed

  @@db_client = $db_client

  attr_accessor :id, :user_id, :description, :created_at, :updated_at

  def initialize(user_id, description)
    @name  = name
    @email = email
  end

  def save!
    return true if self.id != nil
    self.id = @@id
    @@db_client.insert_user(self)
    self.created_at =  self.updated_at = Time.now.to_i
    @@db_client.insert_feed(self)
    return true
  end
end
