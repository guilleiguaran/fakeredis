$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'fakeredis'
require "fakeredis/rspec"

require "support/shared_examples/sortable"

def fakeredis?
  true
end
