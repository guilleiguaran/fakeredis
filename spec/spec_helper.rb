$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'fakeredis'
require "fakeredis/rspec"

$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..')))
Dir["spec/support/**/*.rb"].each {|x| require x}

def fakeredis?
  true
end
