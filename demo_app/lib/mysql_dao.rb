class MySQLDao
  attr_accessor :client

  INSERT_USER="INSERT INTO users (id, name, email) VALUES(%d, '%s', '%s')"
  INSERT_FEED="INSERT INTO feeds (id, user_id, description, created_at, updated_at) VALUES (%d, %d ,'%s', %d, %d)"
  INSERT_FEED_ITEM="INSERT INTO feed_items (id, feed_id, item_type, created_at, payload) VALUES (%d, %d, '%s', %d, '%s')"
  SELECT_USER_FEEDS="SELECT * from feeds where user_id = %d LIMIT %d"
  SELECT_FEED="SELECT * from feeds where id = %d"
  SELECT_USER="SELECT * from users where id = %d"
  SELECT_FEED_ITEMS="SELECT * from feed_items where feed_id = %d AND created_at > %d ORDER by created_at desc LIMIT %d"

  def select_subscribeed_feeds_sql
    "SELECT DISTINCT * from feed_items where feed_id IN (%s) AND created_at > %d ORDER BY created_at desc LIMIT %d"
  end

  def initialize(user, password, host, port, database)
    @client = Mysql2::Client.new(
      adapter: 'mysql2',
      username: user,
      password: password,
      host: host,
      port: port,
      database: database
    )

    @user_ids = (xquery("select id from users order by id DESC limit 1").first || {"id" => 0})["id"] + 1
    @feed_ids = (xquery("select id from feeds order by id DESC limit 1").first || {"id" => 0})["id"] + 1
    @feed_item_ids = (xquery("select id from feed_items order by id DESC limit 1").first || {"id" => 0})["id"] + 1
  end

  def insert_user(user)
    user_id = @user_ids
    xquery(INSERT_USER, user_id, user.name, user.email)
    @user_ids += 1
    return user_id
  end

  def insert_feed(feed)
    feed_id = @feed_ids
    xquery(
      INSERT_FEED,
      feed_id,
      feed.user_id,
      feed.description,
      feed.created_at,
      feed.updated_at
    )
    @feed_ids += 1
    return feed_id
  end

  def select_user_feeds(user_id)
    raw_feeds = xquery(
      SELECT_USER_FEEDS,
      user_id,
      100
    ).to_a
    raw_feeds.map { |raw_feed| Feed.new(ActiveSupport::HashWithIndifferentAccess.new(raw_feed))}
  end

  def select_feed(feed_id)
    raw_feed = xquery(
      SELECT_FEED,
      feed_id
    ).to_a.first
    return nil unless raw_feed
    Feed.new(ActiveSupport::HashWithIndifferentAccess.new(raw_feed))
  end

  def select_user(user_id)
    raw_user = xquery(
      SELECT_USER,
      user_id
    ).to_a.first
    return nil unless raw_user
    User.new(ActiveSupport::HashWithIndifferentAccess.new(raw_user))
  end

  def insert_feed_item(feed_item)
    feed_item_id = @feed_item_ids
    xquery(
      INSERT_FEED_ITEM,
      feed_item_id,
      feed_item.feed_id,
      feed_item.item_type,
      feed_item.created_at,
      feed_item.payload
    )
    @feed_item_ids += 1
    return feed_item_id
  end

  def select_feed_items(feed_id, since, limit)
    raw_feed_items = xquery(
      SELECT_FEED_ITEMS,
      feed_id,
      since,
      limit
    ).to_a
    raw_feed_items.map { |raw_feed_item| FeedItem.new(ActiveSupport::HashWithIndifferentAccess.new(raw_feed_item))}
  end

  def select_feed_items_for_subscription(feed_ids, since, limit)
    raw_feed_items = xquery(
      select_subscribeed_feeds_sql,
      feed_ids.join(','),
      since,
      limit
    ).to_a
    raw_feed_items.map { |raw_feed_item| FeedItem.new(ActiveSupport::HashWithIndifferentAccess.new(raw_feed_item))}
  end

  def xquery(*args)
    query = sprintf(*args)
    @client.query(query)
  end
end
