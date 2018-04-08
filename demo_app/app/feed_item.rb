module FeedItemTypes
  TEXT='t'

  def self.valid?(type)
    [TEXT].include?(type)
  end
end

class FeedItem
  attr_accessor :id, :feed_id, :item_type, :created_at, :payload

  def initialize(args)
    @id = args[:id]
    @item_type = args.fetch(:item_type)
    fail "invalid feed type #{args.fetch(:item_type)}" unless @item_type
    @feed_id = args.fetch(:feed_id)
    @created_at = args[:created_at]
    @payload = args.fetch(:payload)
  end

  def self.find_by_feed_id(args = {})
    since = args[:since] || 0
    feed_id = args.fetch(:feed_id)
    DbDAO.client.select_feed_items(feed_id, since, 100)
  end

  def self.find_by_feed_ids(args = {})
    since = args[:since] || 0
    feed_ids = args.fetch(:feed_ids)
    DbDAO.client.select_feed_items_for_subscription(feed_ids, since, 100)
  end



  def self.text_feed_item_payload(text)
    { text: text }.to_json
  end

  def save!
    return self if self.id != nil
    self.created_at = Time.now.to_i
    id = DbDAO.client.insert_feed_item(self)
    self.id = id
    self
  end

  def to_json
    {
      data: {
        type: 'feed_item',
        id: self.id,
        feed_id: self.feed_id,
        item_type: self.item_type,
        created_at: self.created_at,
        payload: JSON.parse(self.payload)
      }
    }
  end
end
