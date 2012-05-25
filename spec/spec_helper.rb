$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'fakeredis'

RSpec.configure do |config|
  config.before do
    Redis.new.flushall
  end
end

def fakeredis?
  true
end
