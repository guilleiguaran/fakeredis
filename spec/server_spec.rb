require 'spec_helper'

module FakeRedis
  describe "ServerMethods" do

    before(:each) do
      @client = FakeRedis::Redis.new
    end

    it "should return the number of keys in the selected database" do
      @client.set("key1", "1")
      @client.set("key2", "2")
      @client.set("key2", "two")

      @client.dbsize.should == 2
    end

    it "should get debugging information about a key" do
      @client.set("key1", "1")

      @client.debug_object("key1").should == "1".inspect
    end

    it "should get information and statistics about the server" do
      @client.info.key?("redis_version").should == true
    end
  end
end
