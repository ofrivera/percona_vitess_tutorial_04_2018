class DbDAO
  class << self
    def client
      @client ||= begin
                    if ENV['VITESS_READY_QUERIES'] == 'no'
                      MySQLDao.new(ENV['MYSQL_USER'],
                                   ENV['MYSQL_PASSWORD'],
                                   ENV['MYSQL_HOST'],
                                   ENV['MYSQL_PORT'],
                                   ENV['MYSQL_DB_NAME'])
                    else
                      VitessDao.new(ENV['MYSQL_USER'],
                                   ENV['MYSQL_PASSWORD'],
                                   ENV['MYSQL_HOST'],
                                   ENV['MYSQL_PORT'],
                                   ENV['MYSQL_DB_NAME'])
                    end
                  end
    end
  end
end
