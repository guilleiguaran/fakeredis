require 'spec_helper'

module FakeRedis
  describe "Compatibility" do
    it "should be accessible throught FakeRedis::Redis" do
      lambda { FakeRedis::Redis.new }.should_not raise_error
    end
  end
end
