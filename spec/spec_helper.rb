$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'fakeredis'
require "fakeredis/rspec"

require "support/shared_examples/sortable"

RSpec.configure do |config|
  # replaces -b -fdoc --color in .rspec
  config.color = true
  config.default_formatter = "doc"
  config.backtrace_exclusion_patterns = []

  config.mock_with :rspec do |c|
    # TODO: upgrade should syntax to expect syntax
    c.syntax = [:should, :expect]
  end

  config.expect_with :rspec do |c|
    # TODO: upgrade should syntax to expect syntax
    c.syntax = [:should, :expect]
  end
end

def fakeredis?
  true
end
