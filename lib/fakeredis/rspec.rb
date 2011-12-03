# Require this either in your Gemfile or in RSpec's 
# support scripts. Examples: 
#
#   # Gemfile
#   group :test do
#     gem "rspec"
#     gem "fakeredis", :require => "fakeredis/rspec"
#   end 
#
#   # spec/support/fakeredis.rb
#   require 'fakeredis/rspec'
#

require 'rspec/core'
require 'fakeredis'

RSpec.configure do |c|
  
  c.before do    
    redis = Redis.current
    redis.flushdb if redis.client.connection.is_a?(Redis::Connection::Memory)
  end
  
end
