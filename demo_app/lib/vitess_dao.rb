class VitessDao < MySQLDao
  def select_subscribeed_feeds_sql
    "SELECT DISTINCT id, feed_id, item_type, payload, created_at  from feed_items where feed_id IN (%s) AND created_at > %d ORDER BY created_at desc LIMIT %d"
  end
end
