class User
  attr_accessor :id, :name, :email

  def initialize(args)
    @name  = args.fetch(:name)
    @email = args.fetch(:email)
    @id = args[:id]
  end

  def create_feed(description)
    raise "can't create feed for an user that is not persisted" unless self.id
    feed = Feed.new(user_id: self.id, description: description)
    feed.save!
  end

  def feeds
    Feed.find_by_user_id(self.id)
  end

  def save!
    return true if self.id != nil
    user_id = DbDAO.client.insert_user(self)
    self.id = user_id
    self
  end

  def to_json
    {
      data: {
        id: self.id,
        type: 'user',
        name: self.name,
        email: self.email,
        feeds: feeds.map(&:to_json)
      }
    }
  end
end

