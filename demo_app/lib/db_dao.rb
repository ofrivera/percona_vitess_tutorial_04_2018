class DbDAO
  class << self
    def client
      @client ||= begin
                    if ENV['DB_ADAPTER'] == 'mysql'
                      MySQLDao.new('mysql_user', 'mysql_password', 'macondo', '15306', 'test_keyspace')
                    elsif ENV['DB_ADAPTER'] == 'vitess'
                      fail "todo"
                    else
                      fail "Invalid ENV['DB_ADAPTER']. Valid values: mysql, vitess"
                    end
                  end
    end
  end
end
