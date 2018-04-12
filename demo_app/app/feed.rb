class Feed
  attr_accessor :id, :user_id, :description, :created_at, :updated_at

  def initialize(args = {})
    @user_id  = args.fetch(:user_id)
    @description = args.fetch(:description)
    @created_at = args[:created_at]
    @updated_at = args[:updated_at]
    @id = args[:id]
  end

  def add_text_item(text)
    payload = FeedItem.text_feed_item_payload(text)
    feed_item = FeedItem.new(feed_id: self.id, item_type: 't', payload: payload)
    feed_item.save!
    feed_item
  end

  def self.find_by_id(id)
    DbDAO.client.select_feed(id)
  end

  def self.find_by_user_id(user_id)
    DbDAO.client.select_user_feeds(user_id)
  end

  def save!
    return self if self.id != nil
    self.created_at =  self.updated_at = Time.now.strftime("%s%6N")
    id = DbDAO.client.insert_feed(self)
    self.id = id
    self
  end

  def to_json
    {
      data: {
        id: self.id,
        type: 'feed',
        user_id: self.user_id,
        description: self.description,
        created_at: self.created_at,
        updated_at: self.updated_at
      }
    }
  end
end
