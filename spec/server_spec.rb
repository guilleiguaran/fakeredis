require 'spec_helper'

module FakeRedis
  describe "ServerMethods" do

    before(:each) do
      @client = FakeRedis::Redis.new
    end

    it "should return database size" do
      @client.set("key1", "1")
      @client.set("key2", "2")
      @client.set("key2", "two")

      @client.dbsize.should == 2
    end

    it "should debug a object" do
      @client.set("key1", "1")

      @client.debug_object("key1").should == "1".inspect
    end

    it "should return server info" do
      @client.info.key?("redis_version").should == true
    end
  end
end
