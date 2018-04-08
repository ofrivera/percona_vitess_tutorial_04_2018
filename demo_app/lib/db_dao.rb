class DbDAO
  class << self
    def client
      @client ||= begin
                    if ENV['DB_ADAPTER'] == 'mysql'
                      MySQLDao.new(ENV['MYSQL_USER'],
                                   ENV['MYSQL_PASSWORD'],
                                   ENV['MYSQL_HOST'],
                                   ENV['MYSQL_PORT'],
                                   ENV['MYSQL_DB_NAME'])
                    elsif ENV['DB_ADAPTER'] == 'vitess'
                      VitessDao.new(ENV['MYSQL_USER'],
                                   ENV['MYSQL_PASSWORD'],
                                   ENV['MYSQL_HOST'],
                                   ENV['MYSQL_PORT'],
                                   ENV['MYSQL_DB_NAME'])
                    else
                      fail "Invalid ENV['DB_ADAPTER']. Valid values: mysql, vitess"
                    end
                  end
    end
  end
end
