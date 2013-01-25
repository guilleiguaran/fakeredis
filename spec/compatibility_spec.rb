require 'spec_helper'

module FakeRedis
  describe "Compatibility" do
    it "should be accessible through FakeRedis::Redis" do
      lambda { FakeRedis::Redis.new }.should_not raise_error
    end
  end
end
