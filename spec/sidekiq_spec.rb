require 'spec_helper'
require 'fakeredis/sidekiq'

module FakeRedis
  describe "Sidekiq" do
    it "should mock Sidekiq redis" do
      ::Sidekiq.redis do |c|
        c.should be_kind_of Redis
      end
    end
  end
end
