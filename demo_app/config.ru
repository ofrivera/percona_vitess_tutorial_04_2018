$LOAD_PATH << File.join(File.dirname(__FILE__))

require 'app'
require 'logger'

STDOUT.sync = true
use Rack::CommonLogger, Logger.new(STDOUT)
run App
